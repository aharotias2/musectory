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
    public interface PlaylistBoxInterface {
        public abstract string? playlist_name { get; set; }
        public abstract uint image_size { get; set; }
        public abstract uint get_list_size();
        public abstract Tatam.FileInfo? get_file_info();
        public abstract Tatam.FileInfo? get_file_info_at_index(uint index);
        public abstract PlaylistItem? get_current_item();
        public abstract PlaylistItem? get_item_at_index(uint index);
        public abstract void add_item(Tatam.FileInfo? item);
        public abstract void add_items_all(Gee.List<Tatam.FileInfo?> list);
        public abstract void toggle_status();
        public abstract void set_shuffling(bool shuffle_on);
        public abstract void set_repeating(bool repeat_on);
        public abstract uint get_index();
        public abstract void set_index(uint index);
        public abstract uint max_index();
        public abstract bool has_previous();
        public abstract bool has_next();
        public abstract void next();
        public abstract void previous();
        public abstract void remove_item_at_index(uint index);
        public abstract void remove_all();
        public abstract void set_artwork_size(uint size);
        public abstract void load_list_from_file(string m3u_file_path) throws GLib.Error, FileError;
        public abstract bool move_up_items();
        public abstract bool move_down_items();
        public abstract bool remove_items();
        public abstract void unselect_all();
        public signal void item_activated(uint index, Tatam.FileInfo item);
        public signal void playlist_changed();
    }

    public class PlaylistBox : Bin, PlaylistBoxInterface {
        private GLib.ListStore? store;
        private ScrolledWindow? scrolled;
        private FileInfoAdapter freader;
        private Tracker tracker;
        private ListBox? list_box;
        public string? playlist_name { get; set; }
        public uint image_size { get; set; }

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
                            set_index(item.get_index());
                            item_activated(tracker.current, item.file_info);
                        }
                    });
                }
                scrolled.add(list_box);
            }
            add(scrolled);
        }

        public uint get_list_size() {
            return store.get_n_items();
        }

        public Tatam.FileInfo? get_file_info() {
            return (Tatam.FileInfo?)store.get_item(tracker.current);
        }

        public Tatam.FileInfo? get_file_info_at_index(uint index) {
            return (Tatam.FileInfo?)store.get_item(index);
        }

        public PlaylistItem? get_current_item() {
            return get_item_at_index(tracker.current);
        }

        public PlaylistItem? get_item_at_index(uint index) {
            PlaylistItem? item = (PlaylistItem?) list_box.get_row_at_index((int) index);
            debug("PlaylistBox.get_item: index = %u, track title = %s", index, item != null ? item.track_title : "null");
            return item;
        }

        public void add_item(Tatam.FileInfo? file_info) {
            if (file_info != null) {
                store.append(file_info);
                tracker.reset(get_list_size(), tracker.current);
                playlist_changed();
            }
        }

        public void add_items_all(Gee.List<Tatam.FileInfo?> file_list) {
            foreach (Tatam.FileInfo? file_info in file_list) {
                if (file_info != null) {
                    store.append(file_info);
                }
            }
            tracker.reset(get_list_size(), tracker.current);
        }

        public void remove_item_at_index(uint n) {
            store.remove(n);
            tracker.reset(get_list_size(), tracker.current < tracker.max ? tracker.current : tracker.max - 1);
            playlist_changed();
        }

        public uint max_index() {
            return tracker.max;
        }

        public bool has_next() {
            return tracker.has_next();
        }

        public bool has_previous() {
            return tracker.has_previous();
        }

        public void set_index(uint index) {
            PlaylistItem? item = null;
            uint size = get_list_size();
            debug("PlaylistBox.set_track: index = %u, size = %u, current track = %u", index, size, tracker.current);
            uint i = 0;
            do {
                item = get_item_at_index(i);
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
            PlaylistItem? item = get_current_item();
            item.clicked();
            item.queue_draw();
        }

        public uint get_index() {
            return tracker.current;
        }

        public void set_shuffling(bool shuffle_on) {
            tracker.shuffling = shuffle_on;
        }

        public void set_repeating(bool repeat_on) {
            tracker.repeating = repeat_on;
        }

        public void next() {
            tracker.next();
            set_index(tracker.current);
        }

        public void previous() {
            tracker.previous();
            set_index(tracker.current);
        }

        public void move_cursor(uint index) {
            debug("playlist move cursor to %u", index);
            list_box.select_row((ListBoxRow) get_item_at_index(index));
        }

        public void remove_all() {
            store.remove_all();
            tracker.reset(0, 0);
        }

        public void set_artwork_size(uint size) {
            PlaylistItem? item = null;
            int i = 0;
            do {
                item = get_item_at_index(i);
                if (item != null) {
                    item.resize_image(size);
                }
                i++;
            } while (item != null);
            image_size = size;
        }

        public void load_list_from_file(string m3u_file_path) throws GLib.Error, FileError {
            string contents;
            if (GLib.FileUtils.test(m3u_file_path, FileTest.EXISTS)) {
                GLib.FileUtils.get_contents(m3u_file_path, out contents);
                Gee.List<string> file_path_list = Tatam.StringUtils.array_to_list(contents.split("\n"));
                remove_all();
                foreach (string file_path in file_path_list) {
                    if (file_path.length > 0 && Files.mimetype_is_audio(file_path)) {
                        Tatam.FileInfo file_info = freader.read_metadata_from_path(file_path);
                        add_item(file_info);
                        debug("load_list_from_file: added %s", file_path);
                    }
                }
                tracker.reset(file_path_list.size, 0);
                playlist_changed();
            }
        }

        private Widget create_list_item(Object object) {
            PlaylistItem list_item = new PlaylistItem((Tatam.FileInfo)object, image_size);
            {
                list_item.set_index(get_list_size());
            }
            return list_item;
        }

        public void on_click_at_index(int index) {
            set_index(index);
            var item = get_item_at_index(index);
            if (item != null) {
                item.clicked();
            }
        }

        public bool move_up_items() {
            bool change_flag = false;
            uint length = store.get_n_items();
            for (int i = 0; i < length; i++) {
                var list_item = list_box.get_row_at_index(i) as PlaylistItem;
                if (list_item.checked) {
                    if (i == 0) {
                        return false;
                    } else {
                        var file_info = get_file_info_at_index(i);
                        store.remove(i);
                        store.insert(i - 1, file_info);
                        var new_list_item = list_box.get_row_at_index(i - 1) as PlaylistItem;
                        new_list_item.checked = true;
                        change_flag = true;
                    }
                }
            }
            if (change_flag) {
                renumber_items();
                playlist_changed();
            }
            return true;
        }

        public bool move_down_items() {
            bool change_flag = false;
            uint length = store.get_n_items();
            for (int i = (int) length - 1; i >= 0; i--) {
                var list_item = list_box.get_row_at_index(i) as PlaylistItem;
                if (list_item.checked) {
                    if (i == length - 1) {
                        return false;
                    } else {
                        var file_info = get_file_info_at_index(i);
                        store.remove(i);
                        store.insert(i + 1, file_info);
                        var new_list_item = list_box.get_row_at_index(i + 1) as PlaylistItem;
                        new_list_item.checked = true;
                        change_flag = true;
                    }
                }
            }
            if (change_flag) {
                renumber_items();
                playlist_changed();
            }
            return true;
        }

        public bool remove_items() {
            bool change_flag = false;
            uint length = store.get_n_items();
            for (int i = (int) length - 1; i >= 0; i--) {
                var list_item = list_box.get_row_at_index(i) as PlaylistItem;
                if (list_item.checked) {
                    store.remove(i);
                    change_flag = true;
                }
            }
            if (change_flag) {
                renumber_items();
                playlist_changed();
            }
            return true;
        }

        public void unselect_all() {
            uint length = store.get_n_items();
            for (int i = 0; i < length; i++) {
                var list_item = list_box.get_row_at_index(i) as PlaylistItem;
                if (list_item.checked) {
                    list_item.checked = false;
                }
            }
        }

        private void renumber_items() {
            uint length = store.get_n_items();
            for (int i = 0; i < length; i++) {
                var list_item = list_box.get_row_at_index(i) as PlaylistItem;
                list_item.set_index(i + 1);
            }
        }
    }
}
