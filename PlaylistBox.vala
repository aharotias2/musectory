/*
 * This file is part of dplayer.
 * 
 *     dplayer is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 * 
 *     dplayer is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 * 
 *     You should have received a copy of the GNU General Public License
 *     along with dplayer.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright 2018 Takayuki Tanaka
 */

using Gtk;
using Pango;
using DPlayer;

namespace DPlayer {
    public class PlaylistBox : Bin {
        private class PlaylistItem : ListBoxRow {
            public int image_size { get; set; }
            private bool playing;
            private PlaylistDrawingArea icon_area;
            public string track_title { get; private set; }
            
            public PlaylistItem(DFileInfo file, int image_size) {
                playing = false;
                debug("PlaylistItem.image_size = %d", image_size);
                this.image_size = image_size;
                EventBox ev_box = new EventBox();
                {
                    Grid grid = new Grid();
                    if (file != null) {
                        Overlay image_overlay = new Overlay();
                        {
                            Gdk.InterpType bilinear = Gdk.InterpType.BILINEAR;
                            Image? image_artwork = null;
                            if (file.artwork != null) {
                                Gdk.Pixbuf scaled_artwork = file.artwork.scale_simple(image_size,
                                                                                      image_size,
                                                                                      bilinear);
                                image_artwork = new Image.from_pixbuf(scaled_artwork);
                                {
                                    image_artwork.set_size_request(image_size, image_size);
                                }
                            }
                            
                            icon_area = new PlaylistDrawingArea();
                            {
                                icon_area.status = PlaylistItemStatus.NORMAL;
                                icon_area.set_area_size(image_size);
                                icon_area.halign = Align.CENTER;
                                icon_area.valign = Align.CENTER;
                                icon_area.status = PlaylistItemStatus.NORMAL;
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
                                title.get_style_context().add_class("title");
                            }

                            string album_year = file.album != null ? file.album : "Unkown Album";
                            if (file.date != null) {
                                album_year += " (" + file.date + ")";
                            }
                        
                            Label album = new Label(album_year);
                            {
                                album.ellipsize = EllipsizeMode.END;
                                album.set_halign(Align.START);
                                album.get_style_context().add_class("album");
                            }

                            Label artist = new Label(file.artist != null ? file.artist : "Unkown Artist");
                            {
                                artist.ellipsize = EllipsizeMode.END;
                                artist.set_halign(Align.START);
                                artist.get_style_context().add_class("artist");
                            }

                            Label genre = new Label(file.genre != null ? file.genre : "Unkown Genre");
                            {
                                genre.ellipsize = EllipsizeMode.END;
                                genre.set_halign(Align.START);
                                genre.get_style_context().add_class("genre");
                            }

                            grid2.attach(title, 0, 0, 4, 1);
                            grid2.attach(album, 0, 1, 4, 1);
                            grid2.attach(artist, 4, 0, 2, 1);
                            grid2.attach(genre, 4, 1, 2, 1);
                            grid2.row_homogeneous = false;
                            grid2.column_homogeneous = true;
                        }
            
                        Label time = new Label(file.time_length);
            
                        grid.attach(image_overlay, 0, 0, 1, 1);
                        grid.attach(grid2, 1, 0, 7, 1);
                        grid.attach(time, 8, 0, 1, 1);
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
                query_tooltip.connect ((x, y, keyboard_tooltip, tooltip) => {
                        tooltip.set_icon(file.artwork.scale_simple(256, 256, Gdk.InterpType.BILINEAR));
                        tooltip.set_text(
                            (file.title != null ? file.title : (file.name != null ? file.name : "Unkown Track")) + "\n" +
                            (file.artist != null ? file.artist : "Unkown Artist") + "\n" + 
                            (file.album != null ? file.album + "\n" : "") + 
                            (file.genre != null ? file.genre + "\n" : "") +
                            (file.date != null ? file.date : "")
                            );
                        return true;
                    });
            }

            public void set_index(uint index) {
                icon_area.index = index;
            }
            
            public void on_enter() {
                if (!playing) {
                    icon_area.status = PlaylistItemStatus.PAUSED;
                }
            }

            public void on_leave() {
                if (!playing) {
                    icon_area.status = PlaylistItemStatus.NORMAL;
                }
            }

            public void set_as_playing() {
                playing = true;
                icon_area.status = PlaylistItemStatus.PLAYING;
            }

            public void set_as_number() {
                playing = false;
                icon_area.status = PlaylistItemStatus.NORMAL;
            }

            public void set_as_paused() {
                playing = true;
                icon_area.status = PlaylistItemStatus.PAUSED;
            }

            public void on_click() {
                if (icon_area.status == PlaylistItemStatus.PLAYING) {
                    set_as_paused();
                } else {
                    set_as_playing();
                }
            }

            public bool get_playing() {
                return playing;
            }
        }

        private GLib.ListStore? store;
        private ScrolledWindow? scrolled;
        private Tracker tracker;
        public ListBox? list_box { get; set; }
        public int image_size { get; set; }
        
        public PlaylistBox() {
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
            return list;
        }

        private int get_image_size_local() {
            return image_size;
        }
        
        private Widget create_list_item(Object object) {
            PlaylistItem list_item = new PlaylistItem((DFileInfo) object, get_image_size_local());
            list_item.set_index(get_list_size());
            return list_item;
        }

        public void append_list_from_path(string file_path) {
            int index = 0;

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

            int i = 0;

            append_list(new_playlist);

            debug("playlist append list: current track = %u", tracker.current);

            tracker.reset(get_list_size(), tracker.current);
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
                            item.set_as_playing();
                        }
                    } else {
                        item.set_as_number();
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
        }

        public void move_to_prev_track() {
            move_cursor((int) tracker.dec());
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

        public void new_list_from_path(string path) {
            store.remove_all();
            tracker.reset(0, 0);
            append_list_from_path(path);
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

        private uint get_list_size() {
            uint i = 0;
            while (store.get_item(i) != null) {
                i++;
            }
            return i;
        }
    }
}
