/*
 * This file is part of mpd.
 * 
 *     mpd is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 * 
 *     mpd is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 * 
 *     You should have received a copy of the GNU General Public License
 *     along with mpd.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright 2018 Takayuki Tanaka
 */

using Gtk;
using Pango;
using Mpd;

namespace Mpd {
    public class PlaylistBox : Bin {
        private class PlaylistItem : ListBoxRow {
            public int image_size { get; set; }
            private PlaylistItemStatus status;
            private PlaylistDrawingArea icon_area;
            public string track_title { get; private set; }
            private string tooltip_text;
            private Gdk.Pixbuf tooltip_image;
            private MenuButton button;
            public DFileInfo file_info;
            public signal void menu_activated(MenuType type, uint index);
            private Image? image_artwork;
            
            public PlaylistItem(DFileInfo file, int image_size) {
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
                                Gdk.Pixbuf scaled_artwork = file.artwork.scale_simple(image_size,
                                                                                      image_size,
                                                                                      bilinear);
                                image_artwork = new Image.from_pixbuf(scaled_artwork);
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
                            if (file.date != null) {
                                album_year += " (" + file.date + ")";
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
            
                        Label time = new Label(file.time_length);

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
                    (file.date != null ? " (%s)".printf(file.date) : ""),
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

        private GLib.ListStore? store;
        private ScrolledWindow? scrolled;
        private Tracker tracker;
        public ListBox? list_box { get; set; }
        public int image_size { get; set; }
        public string? name { get; set; }
        public signal void changed(List<string> file_path_list);
        
        public PlaylistBox() {
            name = null;
            store = new GLib.ListStore(typeof(DFileInfo));
            tracker = new Tracker();
            scrolled = new ScrolledWindow(null, null);
            {
                list_box = new ListBox();
                {
                    list_box.bind_model(store, create_list_item);
                    list_box.activate_on_single_click = true;
                    list_box.selection_mode = SelectionMode.SINGLE;
                }
                scrolled.add(list_box);
            }
            add(scrolled);
        }

        private PlaylistItem? get_item(int index) {
            PlaylistItem? item = (PlaylistItem?) list_box.get_row_at_index(index);
            debug("PlaylistBox.get_item: index = %d, track title = %s", index, item != null ? item.track_title : "null");
            return item;
        }
        
        public void on_click_at_index(int index) {
            set_track(index);
            var item = get_item(index);
            if (item != null) {
                item.on_click();
            }
        }
            
        public void append_list(List<DFileInfo?> file_list) {
            foreach (DFileInfo? file_info in file_list) {
                add_item(file_info);
            }
        }
    
        public void add_item(DFileInfo? file_info) {
            if (file_info != null) {
                store.append(file_info);
            }
        }

        public int get_index_from_path(string file_path) {
            DFileInfo? file = null;
            int i = 0;
            do {
                file = (DFileInfo?) store.get_item(i++);
                if (file != null) {
                    if (file_path.collate(file.path) == 0) {
                        return --i;
                    }
                }
            } while (file != null);
            return -1;
        }

        public DFileInfo? get_file_info_from_path(string path) {
            DFileInfo? file = null;
            int i = 0;
            do {
                file = (DFileInfo?) store.get_item(i++);
                if (file != null) {
                    if (path.collate(file.path) == 0) {
                        return file;
                    }
                }
            } while (file != null);
            return null;
        }

        public List<string> get_file_path_list() {
            var list = new List<string>();
            DFileInfo? file = null;
            int i = 0;
            do {
                file = (DFileInfo?) store.get_item(i++);
                if (file != null) {
                    list.append(file.path);
                }
            } while (file != null);

            foreach (string a in list) {
                debug("PlaylistBox.get_file_path_list: %s", a);
            }
            
            return list;
        }

        public void append_list_from_path(string file_path) {
            var new_playlist = new List<DFileInfo?>();

            var file_util = new DFileUtils(file_path);
            DFileType file_type;
            try {
                file_type = file_util.determine_file_type();
                switch (file_type) {
                case DFileType.FILE:
                    new_playlist = new DFileUtils(Path.get_dirname(file_path)).find_file_infos_recursively();
                    break;
                case DFileType.DISC:
                case DFileType.DIRECTORY:
                    new_playlist = new DFileUtils(file_path).find_file_infos_recursively();
                    break;
                case DFileType.PARENT:
                default:
                    return;
                }
            } catch (FileError e) {
                stderr.printf("new playlist creation error.\n");
                return;
            }

            if (new_playlist.length() == 0) {
                return;
            }

            append_list(new_playlist);

            tracker.reset(get_list_size(), tracker.current);
            debug("playlist append list: current track = %u", tracker.current);
        }

        public void append_list_from_path_list(List<string> path_list) {
            List<DFileInfo?> new_playlist = MPlayer.get_file_info_and_artwork_list_from_file_list(path_list);
            append_list(new_playlist);
            tracker.reset(get_list_size(), tracker.current);
            debug("playlist append list: current track = %u", tracker.current);
        }

        public void delete_track_at_index(int n) {
            store.remove(n);
            tracker.reset(get_list_size(), tracker.current < tracker.max ? tracker.current : tracker.max - 1);
        }

        
        public uint get_max_track() {
            return tracker.max;
        }

        public bool track_is_last() {
            return !tracker.has_next();
        }

        public bool track_is_first() {
            return !tracker.has_prev();
        }

        public void set_track(int index) {
            PlaylistItem? item = null;
            int size = (int) get_list_size();
            debug("PlaylistBox.set_track: index = %d, size = %d, current track = %u", index, size, tracker.current);
            int i = 0;
            do {
                item = get_item(i);
                if (item != null) {
                    if (i == index) {
                        if (i == tracker.current) {
                            item.on_click();
                        } else {
                            item.set_status(PlaylistItemStatus.PLAYING);
                        }
                    } else {
                        item.set_status(PlaylistItemStatus.NORMAL);
                    }
                }
                i++;
            } while (item != null && i < size);
            tracker.current = index;
            move_cursor(index);
        }

        public void toggle_status() {
            PlaylistItem? item = get_item((int) tracker.current);
            item.on_click();
            item.queue_draw();
        }
        
        public uint get_track() {
            return tracker.current;
        }

        public void toggle_shuffle() {
            tracker.toggle_shuffle();
        }

        public void toggle_repeat() {
            tracker.toggle_repeat();
        }

        public void move_to_next_track() {
            move_cursor((int) tracker.inc());
            set_track((int)tracker.current);
        }

        public void move_to_prev_track() {
            move_cursor((int) tracker.dec());
            set_track((int)tracker.current);
        }

        public void move_cursor(int index) {
            debug("playlist move cursor to %d", index);
            list_box.select_row((ListBoxRow) get_item(index));
        }

        public DFileInfo? nth_track_data(uint n) {
            return (DFileInfo?) store.get_item(n);
        }

        public DFileInfo? track_data() {
            debug(tracker.current.to_string() + "th data:");
            if (tracker.current <= tracker.max) {
                return nth_track_data(tracker.current);
            } else {
                return null;
            }
        }

        public void clear() {
            store.remove_all();
            tracker.reset(0, 0);
        }

        public void resize_artworks(int size) {
            PlaylistItem? item = null;
            int i = 0;
            do {
                item = get_item(i);
                if (item != null) {
                    item.resize_image(size);
                }
                i++;
            } while (item != null);
            image_size = size;
        }
        
        public void new_list_from_path(string path) {
            store.remove_all();
            tracker.reset(0, 0);
            append_list_from_path(path);
        }

        public void new_list_from_path_list(List<string> path_list) {
            store.remove_all();
            tracker.reset(0, 0);
            append_list_from_path_list(path_list);
        }
        
        public void load_list_from_file(string m3u_file_path) {
            string contents;
            if (FileUtils.test(m3u_file_path, FileTest.EXISTS)) {
                FileUtils.get_contents(m3u_file_path, out contents);
                List<string> list = MyUtils.StringUtils.array2list(contents.split("\n"));
                new_list_from_path_list(list);
            }
        }
        
        private void create_from_directory(string dir, ref List<DFileInfo?> playlist, bool recursive) {
            var dir_list = new List<string>();
            var file_list = new List<DFileInfo?>();

            var dirutil = new DFileUtils(dir);
            try {
                dirutil.find_dir_files(ref dir_list, ref file_list);
            } catch (FileError e) {
                return;
            }

            if (file_list.length() > 0) {
                playlist.concat((owned) file_list);
            }

            if (recursive) {
                foreach (string sub_dir in dir_list) {
                    create_from_directory(
                        Path.build_path(Path.DIR_SEPARATOR_S, dir, sub_dir), ref playlist, recursive);
                }
            }
        }

        private int get_image_size_local() {
            return image_size;
        }
        
        private Widget create_list_item(Object object) {
            PlaylistItem list_item = new PlaylistItem((DFileInfo) object, get_image_size_local());
            list_item.set_index(get_list_size());
            list_item.menu_activated.connect((type, index) => {
                    DFileInfo file_info = get_item((int) index).file_info;
                    uint size = get_list_size();
                    if (type == MenuType.REMOVE) {
                        store.remove(index);
                        changed(get_file_path_list());
                    } else if (type == MenuType.MOVE_UP) {
                        if (index > 0) {
                            store.insert(index - 1, file_info);
                            store.remove(index + 1);
                            changed(get_file_path_list());
                        }
                    } else if (type == MenuType.MOVE_DOWN) {
                        if (index < size - 1) {
                            store.insert(index + 2, file_info);
                            store.remove(index);
                            changed(get_file_path_list());
                        }
                    }
                });
            return list_item;
        }

        private uint get_list_size() {
            uint i = 0;
            while (store.get_item(i) != null) {
                i++;
            }
            return i;
        }
    }
}
