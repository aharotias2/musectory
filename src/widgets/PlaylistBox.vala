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
 * Copyright 2018 Takayuki Tanaka
 */

using Gtk;
using Pango;
using Moegi;

namespace Moegi {
    public class PlaylistBox : Bin {
        public signal void item_activated(uint index, Moegi.FileInfo item);
        public signal void playlist_changed();

        private GLib.ListStore? store;
        private ScrolledWindow? scrolled;
        private FileInfoAdapter freader;
        private Tracker tracker;
        private ListBox? list_box;
        public string? playlist_name { get; set; }
        public uint image_size { get; set; }
        public SmallTime total_time { get; private set; }

        public PlaylistBox() {
            freader = new FileInfoAdapter();
            name = null;
            store = new GLib.ListStore(typeof(Moegi.FileInfo));
            tracker = new Tracker();
            scrolled = new ScrolledWindow(null, null);
            {
                list_box = new ListBox();
                {
                    list_box.bind_model(store, create_list_item);
                    list_box.activate_on_single_click = false;
                    list_box.selection_mode = SelectionMode.NONE;
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

        public Moegi.FileInfo? get_file_info() {
            return (Moegi.FileInfo?)store.get_item(tracker.current);
        }

        public Moegi.FileInfo? get_file_info_at_index(uint index) {
            return (Moegi.FileInfo?)store.get_item(index);
        }

        public PlaylistItem? get_current_item() {
            return get_item_at_index(tracker.current);
        }

        public PlaylistItem? get_item_at_index(uint index) {
            PlaylistItem? item = (PlaylistItem?) list_box.get_row_at_index((int) index);
            debug("PlaylistBox.get_item: index = %u, track title = %s", index, item != null ? item.track_title : "null");
            return item;
        }

        public void add_item(Moegi.FileInfo? file_info) {
            if (file_info != null) {
                store.append(file_info);
                tracker.reset(get_list_size(), tracker.current);
                calc_total_time();
                playlist_changed();
            }
        }

        public void add_items_all(Gee.List<Moegi.FileInfo?> file_list) {
            foreach (Moegi.FileInfo? file_info in file_list) {
                if (file_info != null) {
                    store.append(file_info);
                }
            }
            tracker.reset(get_list_size(), tracker.current);
        }

        public void remove_item_at_index(uint n) {
            store.remove(n);
            tracker.reset(get_list_size(), tracker.current < tracker.max ? tracker.current : tracker.max - 1);
            calc_total_time();
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
            tracker.current = index;
            move_cursor(index);
            debug("PlaylistBox.set_track: index = %u, size = %u, current track = %u", index, size, tracker.current);
            uint i = 0;
            do {
                item = get_item_at_index(i);
                if (item != null) {
                    if (i == index) {
                        if (i == tracker.current) {
                            item.clicked();
                        } else {
                            item.set_status(PLAYING);
                        }
                    } else {
                        item.set_status(NORMAL);
                    }
                }
                i++;
            } while (item != null && i < size);
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
                Gee.List<string> file_path_list = Moegi.StringUtils.array_to_list(contents.split("\n"));
                remove_all();
                foreach (string file_path in file_path_list) {
                    if (file_path.length > 0 && Files.mimetype_is_audio(file_path)) {
                        Moegi.FileInfo file_info = freader.read_metadata_from_path(file_path);
                        add_item(file_info);
                        debug("load_list_from_file: added %s", file_path);
                    }
                }
                tracker.reset(file_path_list.size, 0);
                calc_total_time();
                playlist_changed();
            }
        }

        private Widget create_list_item(Object object) {
            PlaylistItem list_item = new PlaylistItem((Moegi.FileInfo)object, image_size);
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
                        if (i == tracker.current) {
                            tracker.current--;
                            move_cursor(tracker.current);
                        } else if (i - 1 == tracker.current) {
                            tracker.current++;
                            move_cursor(tracker.current);
                        }
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
                        if (i == tracker.current) {
                            tracker.current++;
                            move_cursor(tracker.current);
                        } else if (i + 1 == tracker.current) {
                            tracker.current--;
                            move_cursor(tracker.current);
                        }
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
            uint delete_count = 0;
            for (int i = (int) length - 1; i >= 0; i--) {
                var list_item = list_box.get_row_at_index(i) as PlaylistItem;
                if (list_item.checked) {
                    store.remove(i);
                    delete_count++;
                    change_flag = true;
                    if (i < tracker.current) {
                        tracker.current--;
                        move_cursor(tracker.current);
                    } else if (i == tracker.current && delete_count == length) {
                        tracker.current = -1;
                        move_cursor(tracker.current);
                    }
                }
            }
            if (change_flag) {
                renumber_items();
                calc_total_time();
                playlist_changed();
            }
            return true;
        }

        public int count_checked() {
            int result = 0;
            uint length = store.get_n_items();
            for (int i = 0; i < length; i++) {
                var list_item = list_box.get_row_at_index(i) as PlaylistItem;
                if (list_item.checked) {
                    result++;
                }
            }
            return result;
        }

        public void select_all() {
            uint length = store.get_n_items();
            for (int i = 0; i < length; i++) {
                var list_item = list_box.get_row_at_index(i) as PlaylistItem;
                if (!list_item.checked) {
                    list_item.checked = true;
                }
            }
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

        private async void calc_total_time() {
            int total_milliseconds = 0;
            uint length = store.get_n_items();
            for (int i = 0; i < length; i++) {
                var list_item = list_box.get_row_at_index(i) as PlaylistItem;
                if (list_item == null) {
                    return;
                }
                total_milliseconds += list_item.file_info.time_length.milliseconds;
            }
            total_time = new SmallTime.from_milliseconds(total_milliseconds);
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
