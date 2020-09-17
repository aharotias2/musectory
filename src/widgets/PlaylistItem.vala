/*
 * This file is part of tatam.
 * 
 *     tatam is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 * 
 *     tatam is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 * 
 *     You should have received a copy of the GNU General Public License
 *     along with tatam.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright 2020 Takayuki Tanaka
 */

using Gtk, Gdk, Pango;

namespace Tatam {
    public class PlaylistItem : ListBoxRow {
        public int image_size { get; set; }
        private PlaylistItemStatus status;
        private PlaylistDrawingArea icon_area;
        public string track_title { get; private set; }
        private string tooltip_text;
        private Gdk.Pixbuf tooltip_image;
        private MenuButton button;
        public Tatam.FileInfo file_info;

        public signal void menu_activated(MenuType type, uint index);

        private Image? image_artwork;
            
        public PlaylistItem(Tatam.FileInfo file, int image_size) {
            file_info = file;
            status = PlaylistItemStatus.NORMAL;
            debug("PlaylistItem.image_size = %d", image_size);
            this.image_size = image_size;
            EventBox ev_box = new EventBox();
            {
                Grid grid = new Grid();
                if (file != null) {
                    Overlay image_overlay = new Overlay();
                    {
                        Gdk.InterpType bilinear = Gdk.InterpType.BILINEAR;
                        image_artwork = null;
                        if (file.artwork != null) {
                            image_artwork = new Image.from_pixbuf(
                                Tatam.PixbufUtils.scale_limited(file.artwork, image_size));
                            {
                                image_artwork.set_size_request(image_size, image_size);
                                image_artwork.halign = Align.CENTER;
                                image_artwork.valign = Align.CENTER;
                            }
                        }
                            
                        icon_area = new PlaylistDrawingArea();
                        {
                            icon_area.status = PlaylistItemStatus.NORMAL;
                            icon_area.set_area_size(image_size);
                            icon_area.halign = Align.CENTER;
                            icon_area.valign = Align.CENTER;
                            icon_area.index = get_index();
                            icon_area.does_draw_outline = true;
                        }

                        image_overlay.add_overlay(image_artwork);
                        image_overlay.add_overlay(icon_area);
                    }

                    Grid grid2 = new Grid();
                    {
                        string? file_title = file.title;
                        if (file_title == null) {
                            file_title = file.name;
                        }
                        if (file_title == null) {
                            file_title = "Unkown Track";
                        }
                        track_title = file_title;

                        Label title = new Label(file_title);
                        {
                            title.ellipsize = EllipsizeMode.END;
                            title.set_halign(Align.START);
                            title.get_style_context().add_class("playlist_title");
                        }

                        string album_year = file.album != null ? file.album : "Unkown Album";
                        if (file.date != 0) {
                            album_year += " (" + file.date.to_string() + ")";
                        }
                        
                        Label album = new Label(album_year);
                        {
                            album.ellipsize = EllipsizeMode.END;
                            album.set_halign(Align.START);
                            album.get_style_context().add_class("playlist_album");
                        }

                        Label artist = new Label(file.artist != null ? file.artist : "Unkown Artist");
                        {
                            artist.ellipsize = EllipsizeMode.END;
                            artist.set_halign(Align.START);
                            artist.get_style_context().add_class("playlist_artist");
                        }

                        Label genre = new Label(file.genre != null ? file.genre : "Unkown Genre");
                        {
                            genre.ellipsize = EllipsizeMode.END;
                            genre.set_halign(Align.START);
                            genre.get_style_context().add_class("playlist_genre");
                        }

                        grid2.attach(title, 0, 0, 5, 1);
                        grid2.attach(artist, 0, 1, 5, 1);
                        grid2.attach(album, 5, 0, 2, 1);
                        grid2.attach(genre, 5, 1, 2, 1);
                        grid2.row_homogeneous = false;
                        grid2.column_homogeneous = true;
                    }
            
                    Label time = new Label(file.time_length.to_string());

                    button = new Gtk.MenuButton();
                    {
                        var image = new Image.from_icon_name(IconName.Symbolic.VIEW_MORE, IconSize.BUTTON);
                        var menu = new Gtk.Menu();
                        {
                            var menu_item_remove = new Gtk.ImageMenuItem.with_label(Text.MENU_REMOVE_ITEM);
                            {
                                menu_item_remove.always_show_image = true;
                                menu_item_remove.image = new Image.from_icon_name(
                                    IconName.Symbolic.LIST_REMOVE,IconSize.SMALL_TOOLBAR);
                                menu_item_remove.activate.connect(() => {
                                        menu_activated(MenuType.REMOVE, get_index());
                                    });
                            }

                            var menu_item_go_up = new Gtk.ImageMenuItem.with_label(Text.MENU_MOVE_UP);
                            {
                                menu_item_go_up.always_show_image = true;
                                menu_item_go_up.image = new Image.from_icon_name(
                                    IconName.Symbolic.GO_UP,IconSize.SMALL_TOOLBAR);
                                menu_item_go_up.activate.connect(() => {
                                        menu_activated(MenuType.MOVE_UP, get_index());
                                    });
                            }

                            var menu_item_go_down = new Gtk.ImageMenuItem.with_label(Text.MENU_MOVE_DOWN);
                            {
                                menu_item_go_down.always_show_image = true;
                                menu_item_go_down.image = new Image.from_icon_name(
                                    IconName.Symbolic.GO_DOWN,IconSize.SMALL_TOOLBAR);
                                menu_item_go_down.activate.connect(() => {
                                        menu_activated(MenuType.MOVE_DOWN, get_index());
                                    });
                            }

                            menu.halign = Align.END;
                            menu.add(menu_item_go_up);
                            menu.add(menu_item_go_down);
                            menu.add(menu_item_remove);
                            menu.show_all();
                        }
                        button.add(image);
                        button.get_style_context().add_class(StyleClass.FLAT);
                        button.direction = ArrowType.DOWN;
                        button.halign = Align.CENTER;
                        button.valign = Align.CENTER;
                        button.popup = menu;
                        button.use_popover = false;
                    }

                    grid.attach(image_overlay, 0, 0, 1, 1);
                    grid.attach(grid2, 1, 0, 8, 1);
                    grid.attach(time, 9, 0, 1, 1);
                    grid.attach(button, 10, 0, 1, 1);
                    grid.row_homogeneous = false;
                    grid.column_homogeneous = true;
                }

                ev_box.enter_notify_event.connect((event) => {
                        on_enter();
                        return Source.CONTINUE;
                    });
                ev_box.leave_notify_event.connect((event) => {
                        on_leave();
                        return Source.CONTINUE;
                    });
                ev_box.add(grid);
                ev_box.show_all();
            }

            add(ev_box);

            has_tooltip = true;
            tooltip_text = "%s - %s\n%s%s%s".printf(
                (file.title != null ? file.title : (file.name != null ? file.name : "Unkown Track")),
                (file.artist != null ? file.artist : "Unkown Artist"),
                (file.album != null ? file.album : ""),
                (file.date != 0 ? " (%u)".printf(file.date) : ""),
                (file.genre != null ? " [%s]".printf(file.genre) : "")
                );
            tooltip_image = file.artwork.scale_simple(image_size, image_size, Gdk.InterpType.BILINEAR);
            query_tooltip.connect ((x, y, keyboard_tooltip, tooltip) => {
                    tooltip.set_icon(tooltip_image);
                    tooltip.set_text(tooltip_text);
                    return true;
                });
        }

        public void set_index(uint index) {
            icon_area.index = index;
        }
            
        public void on_enter() {
            switch (status) {
            case PlaylistItemStatus.PLAYING:
                icon_area.status = PlaylistItemStatus.PAUSED;
                break;
            case PlaylistItemStatus.PAUSED:
            case PlaylistItemStatus.NORMAL:
                icon_area.status = PlaylistItemStatus.PLAYING;
                break;
            }
        }

        public void on_leave() {
            switch (status) {
            case PlaylistItemStatus.PLAYING:
                icon_area.status = PlaylistItemStatus.PLAYING;
                break;
            case PlaylistItemStatus.PAUSED:
                icon_area.status = PlaylistItemStatus.PAUSED;
                break;
            case PlaylistItemStatus.NORMAL:
                icon_area.status = PlaylistItemStatus.NORMAL;
                break;
            }
        }

        public void set_status(PlaylistItemStatus status) {
            this.status = status;
            icon_area.status = status;
        }

        public void on_click() {
            switch (status) {
            case PlaylistItemStatus.PLAYING:
                set_status(PlaylistItemStatus.PAUSED);
                break;
            case PlaylistItemStatus.PAUSED:
            case PlaylistItemStatus.NORMAL:
                set_status(PlaylistItemStatus.PLAYING);
                break;
            }
        }

        public void resize_image(int size) {
            if (image_size != size) {
                image_artwork.pixbuf = file_info.artwork.scale_simple(
                    size, size, Gdk.InterpType.BILINEAR);
                icon_area.set_area_size(size);
                image_size = size;
            }
        }
    }
}
