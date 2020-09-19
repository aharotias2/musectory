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
 * Copyright 2018 Takayuki Tanaka
 */

using Gtk;
using Pango;
using Tatam;

namespace Tatam {
    public class PlaylistBox : Bin {
        private GLib.ListStore? store;
        private ScrolledWindow? scrolled;
        private FileInfoAdapter freader;
        private Tracker tracker;
        private ListBox? list_box;
        public int image_size { get; set; }
        public string? name { get; set; }

        public signal void changed(Gee.List<string> file_path_list);
        public signal void row_activated(uint index, Tatam.FileInfo file_info);
        
        public PlaylistBox() {
            freader = new FileInfoAdapter();
            name = null;
            store = new GLib.ListStore(typeof(Tatam.FileInfo));
            tracker = new Tracker();
            scrolled = new ScrolledWindow(null, null);
            {
                list_box = new ListBox();
                {
                    list_box.bind_model(store, create_list_item);
                    list_box.activate_on_single_click = true;
                    list_box.selection_mode = SelectionMode.SINGLE;
                    list_box.row_activated.connect((row) => {
                            PlaylistItem? item = row as PlaylistItem;
                            if (item != null) {
                                row_activated(row.get_index(), item.file_info);
                            }
                        });
                }
                scrolled.add(list_box);
            }
            add(scrolled);
        }

        public Tatam.FileInfo get_current_track_file_info() {
            return get_item().file_info;
        }
        
        public PlaylistItem? get_item(int index = -1) {
            PlaylistItem? item = (PlaylistItem?) list_box.get_row_at_index(index < 0 ? (int) tracker.current : index);
            debug("PlaylistBox.get_item: index = %d, track title = %s", index, item != null ? item.track_title : "null");
            return item;
        }
        
        public void on_click_at_index(int index) {
            set_track(index);
            var item = get_item(index);
            if (item != null) {
                item.clicked();
            }
        }
            
        public void append_list(Gee.List<Tatam.FileInfo?> file_list) {
            foreach (Tatam.FileInfo? file_info in file_list) {
                add_item(file_info);
            }
        }
    
        public void add_item(Tatam.FileInfo? file_info) {
            if (file_info != null) {
                store.append(file_info);
                tracker.reset(get_list_size(), tracker.current);
            }
        }

        public int get_index_from_path(string file_path) {
            Tatam.FileInfo? file = null;
            int i = 0;
            do {
                file = (Tatam.FileInfo?) store.get_item(i++);
                if (file != null) {
                    if (file_path.collate(file.path) == 0) {
                        return --i;
                    }
                }
            } while (file != null);
            return -1;
        }

        public Tatam.FileInfo? get_file_info_from_path(string path) {
            Tatam.FileInfo? file = null;
            int i = 0;
            do {
                file = (Tatam.FileInfo?) store.get_item(i++);
                if (file != null) {
                    if (path.collate(file.path) == 0) {
                        return file;
                    }
                }
            } while (file != null);
            return null;
        }

        public Gee.List<string> get_file_path_list() {
            var list = new Gee.ArrayList<string>();
            Tatam.FileInfo? file = null;
            int i = 0;
            do {
                file = (Tatam.FileInfo?) store.get_item(i++);
                if (file != null) {
                    list.add(file.path);
                }
            } while (file != null);

            foreach (string a in list) {
                debug("PlaylistBox.get_file_path_list: %s", a);
            }
            
            return list;
        }

        public void append_list_from_path(string file_path) {
            Gee.List<Tatam.FileInfo?> new_playlist = new Gee.ArrayList<Tatam.FileInfo?>();

            Tatam.FileType file_type;
            try {
                file_type = Tatam.Files.get_file_type(file_path);
                switch (file_type) {
                case Tatam.FileType.FILE:
                    new_playlist.add(freader.read_metadata_from_path(file_path));
                    break;
                case Tatam.FileType.DISC:
                case Tatam.FileType.DIRECTORY:
                    new_playlist = Tatam.Files.find_file_infos_recursively(file_path);
                    break;
                case Tatam.FileType.PARENT:
                default:
                    return;
                }
            } catch (FileError e) {
                stderr.printf("new playlist creation error.\n");
                return;
            }

            if (new_playlist.size == 0) {
                return;
            }

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
                            item.clicked();
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
            item.clicked();
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

        public Tatam.FileInfo? nth_track_data(uint n) {
            return (Tatam.FileInfo?) store.get_item(n);
        }

        public Tatam.FileInfo? track_data() {
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

        public void load_list_from_file(string m3u_file_path) throws FileError {
            string contents;
            if (GLib.FileUtils.test(m3u_file_path, FileTest.EXISTS)) {
                GLib.FileUtils.get_contents(m3u_file_path, out contents);
                Gee.List<string> file_path_list = Tatam.StringUtils.array_to_list(contents.split("\n"));
                store.remove_all();
                foreach (string file_path in file_path_list) {
                    store.append(freader.read_metadata_from_path(file_path));
                }
                tracker.reset(0, 0);
            }
        }
        
        private void create_from_directory (string dir, ref Gee.List<Tatam.FileInfo?> playlist, bool recursive)
        throws GLib.Error {
            Gee.List<string> dir_list;
            Gee.List<Tatam.FileInfo?> file_list;

            try {
                Tatam.Files.find_dir_files(dir, out dir_list, out file_list);
            } catch (FileError e) {
                return;
            }

            if (file_list.size > 0) {
                playlist.add_all((owned) file_list);
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
            PlaylistItem list_item = new PlaylistItem((Tatam.FileInfo) object, get_image_size_local());
            {
                list_item.set_index(get_list_size());
                list_item.menu_activated.connect((type, index) => {
                        Tatam.FileInfo file_info = get_item((int) index).file_info;
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
            }
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
