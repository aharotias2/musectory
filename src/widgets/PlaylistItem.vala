/*
 * This file is part of moegi-player.
 *
 *     moegi-player is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     moegi-player is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with moegi-player.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright 2020 Takayuki Tanaka
 */

using Gtk, Gdk, Pango;

namespace Moegi {
    public class PlaylistItem : ListBoxRow {
        public enum Status {
            NORMAL, PLAYING, PAUSED, HIDDEN,
        }

        public uint image_size { get; set; }
        public bool mouse_not_out_flag;
        public string track_title { get; private set; }
        public Moegi.FileInfo file_info { get; set; }
        public bool checked {
            get {
                return check_button.active;
            }
            set {
                check_button.active = value;
            }
        }

        private Image? image_artwork;
        private Status status;
        private PlaylistDrawingArea icon_area;
        private Gdk.Pixbuf tooltip_image;
        private MenuButton button;
        private CheckButton check_button;
        private DateTime? click_time1;
        private DateTime? click_time2;

        public PlaylistItem(Moegi.FileInfo file, uint image_size) {
            mouse_not_out_flag = false;
            file_info = file;
            click_time1 = null;
            click_time2 = null;
            status = NORMAL;
            debug("PlaylistItem.image_size = %u", image_size);
            this.image_size = image_size;
            EventBox ev_box = new EventBox();
            {
                Grid grid = new Grid();
                if (file != null) {
                    Overlay image_overlay = new Overlay();
                    {
                        image_artwork = null;
                        if (file.artwork != null) {
                            image_artwork = new Image.from_pixbuf(
                                    Moegi.PixbufUtils.scale(file.artwork, image_size));
                            {
                                image_artwork.set_size_request((int) image_size, (int) image_size);
                                image_artwork.halign = Align.CENTER;
                                image_artwork.valign = Align.CENTER;
                            }
                        }

                        icon_area = new PlaylistDrawingArea();
                        {
                            icon_area.status = NORMAL;
                            icon_area.set_area_size((int) image_size);
                            icon_area.halign = Align.CENTER;
                            icon_area.valign = Align.CENTER;
                            icon_area.index = get_index();
                            icon_area.does_draw_outline = true;
                            icon_area.button_release_event.connect((event) => {
                                clicked();
                                return Source.CONTINUE;
                            });
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

                    Label time = new Label(file.time_length.to_string_without_deciseconds());

                    check_button = new Gtk.CheckButton();
                    {
                        check_button.halign = Gtk.Align.CENTER;
                        check_button.valign = Gtk.Align.CENTER;
                    }

                    grid.attach(image_overlay, 0, 0, 1, 1);
                    grid.attach(grid2, 1, 0, 8, 1);
                    grid.attach(time, 9, 0, 1, 1);
                    grid.attach(check_button, 10, 0, 1, 1);
                    grid.row_homogeneous = false;
                    grid.column_homogeneous = true;
                }

                ev_box.enter_notify_event.connect((event) => {
                    on_enter();
                    return Source.CONTINUE;
                });
                ev_box.leave_notify_event.connect((event) => {
                    mouse_not_out_flag = false;
                    on_leave();
                    click_time1 = null;
                    click_time2 = null;
                    return Source.CONTINUE;
                });
                ev_box.button_press_event.connect((event) => {
                    mouse_not_out_flag = true;
                    return Source.CONTINUE;
                });
                ev_box.button_release_event.connect((event) => {
                    if (mouse_not_out_flag) {
                        if (check_double_click() || event_in_icon_area(event)) {
                            activate();
                        } else {
                            // toggle checked status
                            check_button.active = !check_button.active;
                            if (check_button.active) {
                                this.get_style_context().add_class("playlist_item_selected");
                            } else {
                                this.get_style_context().remove_class("playlist_item_selected");
                            }
                        }
                    }
                    return Source.CONTINUE;
                });
                ev_box.motion_notify_event.connect((event) => {
                    if (event_in_icon_area(event)) {
                        change_cursor(Gdk.CursorType.HAND2);
                    } else {
                        change_cursor(Gdk.CursorType.LEFT_PTR);
                    }
                    return Source.CONTINUE;
                });
                ev_box.add_events(EventMask.POINTER_MOTION_MASK);
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
            tooltip_image = PixbufUtils.scale(file.artwork, image_size);
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
              case PLAYING:
                icon_area.status = PAUSED;
                break;
              case PAUSED:
              case NORMAL:
                icon_area.status = PLAYING;
                break;
              case HIDDEN:
                return;
            }
            icon_area.queue_draw();
        }

        public void on_leave() {
            switch (status) {
              case PLAYING:
                icon_area.status = PLAYING;
                break;
              case PAUSED:
                icon_area.status = PAUSED;
                break;
              case NORMAL:
                icon_area.status = NORMAL;
                break;
              case HIDDEN:
                return;
            }
            icon_area.queue_draw();
        }

        public void set_status(Status status) {
            this.status = status;
            icon_area.status = status;
            if (status == PLAYING || status == PAUSED) {
                this.get_style_context().add_class("playlist_item_playing");
            } else {
                this.get_style_context().remove_class("playlist_item_playing");
            }
        }

        public void clicked() {
            switch (status) {
              case PLAYING:
                set_status(PAUSED);
                break;
              case PAUSED:
              case NORMAL:
                set_status(PLAYING);
                break;
              case HIDDEN:
                return;
            }
            icon_area.queue_draw();
        }

        public void resize_image(uint size) {
            if (image_size != size) {
                image_artwork.pixbuf = PixbufUtils.scale(file_info.artwork, size);
                icon_area.set_area_size((int) size);
                image_size = size;
            }
        }

        private void change_cursor(Gdk.CursorType cursor_type) {
            if (get_parent_window().get_cursor().cursor_type != cursor_type) {
                this.get_parent_window().set_cursor(
                    new Gdk.Cursor.for_display(Gdk.Screen.get_default().get_display(), cursor_type));
            }
        }

        private bool event_in_icon_area(Event event) {
            Allocation icon_area_alloc;
            icon_area.get_allocation(out icon_area_alloc);
            Gdk.Window win = icon_area.get_window();
            int icon_root_x, icon_root_y;
            win.get_root_coords(0, 0, out icon_root_x, out icon_root_y);
            double event_root_x = 0.0, event_root_y = 0.0;
            switch (event.type) {
              case EventType.BUTTON_PRESS:
              case EventType.BUTTON_RELEASE:
                var button_ev = (EventButton) event;
                event_root_x = button_ev.x_root;
                event_root_y = button_ev.y_root;
                break;
              case EventType.MOTION_NOTIFY:
                var button_ev = (EventMotion) event;
                event_root_x = button_ev.x_root;
                event_root_y = button_ev.y_root;
                break;
            default:
                return false;
            }
            if (icon_root_x <= event_root_x <= icon_root_x + icon_area_alloc.width
                    && icon_root_y <= event_root_y <= icon_root_y + icon_area_alloc.height) {
                return true;
            } else {
                return false;
            }
        }

        private bool check_double_click() {
            bool result = false;
            // determine double clicking in 0.5 second.
            if (click_time1 == null) {
                click_time1 = new DateTime.now_local();
            } else {
                click_time2 = new DateTime.now_local();
                TimeSpan span = click_time2.difference(click_time1);
                if (span < 500000) {
                    // double clicked then activate it.
                    result = true;
                }
                click_time1 = null;
                click_time2 = null;
            }
            return result;
        }

        public void print_event_status(Event ev) {
            print("event");
            if (ev.type == EventType.ENTER_NOTIFY || ev.type == EventType.LEAVE_NOTIFY) {
                EventCrossing event = (EventCrossing) ev;
                print(" leave at %0.2f, %0.2f", event.x, event.y);
            } else if (ev.type == EventType.BUTTON_RELEASE || ev.type == EventType.BUTTON_PRESS) {
                EventButton event = (EventButton) ev;
                print(" leave at %0.2f, %0.2f", event.x, event.y);
            }
            print("\n");
        }
    }
}
