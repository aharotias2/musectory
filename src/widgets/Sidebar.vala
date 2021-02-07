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

using Gtk;

namespace Tatam {
    public interface SidebarInterface {
        public abstract int max_width { get; set; }
        public abstract int min_width { get; set; }
        public abstract int max_height { get; set; }
        public abstract int min_height { get; set; }
        public abstract void add_bookmark(string file_path);
        public abstract bool has_bookmark(string bookmark_path);
        public abstract void remove_bookmark(string bookmark_path);
        public abstract Gee.List<string> get_bookmarks();
        public abstract bool has_playlist(string playlist_name);
        public abstract void add_playlist(string playlist_name, string playlist_path);
        public abstract void remove_bookmark_all();
        public abstract void remove_playlist_all();
        public signal void bookmark_directory_selected(string dir_path);
        public signal bool bookmark_del_button_clicked(string dir_path);
        public signal void playlist_selected(string playlist_name, string playlist_path);
        public signal bool playlist_del_button_clicked(string playlist_path);
        public signal void file_chooser_called();
        public signal void bookmark_added(string file_path);
    }

    public class Sidebar : Bin, SidebarInterface {
        public int max_width { get; set; }
        public int min_width { get; set; }
        public int max_height { get; set; }
        public int min_height { get; set; }

        private Box bookmark_box;
        private Gee.Map<string, Gtk.Box> bookmark_buttons;
        private Box playlist_box;
        private Gee.Map<string, Gtk.Box> playlist_buttons;
        private Gee.Map<string, string> playlist_paths;

        public Sidebar() {
            bookmark_buttons = new Gee.HashMap<string, Gtk.Box>();
            playlist_buttons = new Gee.HashMap<string, Gtk.Box>();
            playlist_paths = new Gee.HashMap<string, string>();
        }

        construct {
            var menu_box = new Box(Orientation.VERTICAL, 0);
            {
                var bookmark_label = new Label("Bookmarks");

                bookmark_box = new Box(Orientation.VERTICAL, 0);

                var playlist_label = new Label("Playlists");

                playlist_box = new Box(Orientation.VERTICAL, 0);

                var directory_chooser = new Button();
                {
                    var box = new Box(Orientation.HORIZONTAL, 0);
                    {
                        box.pack_start(new Image.from_icon_name(IconName.FOLDER_OPEN, IconSize.SMALL_TOOLBAR), false, false);
                        box.pack_start(new Label(_("Choose directory...")), false, false);
                    }
                    directory_chooser.relief = ReliefStyle.NONE;
                    directory_chooser.add(box);
                    directory_chooser.clicked.connect(() => {
                        file_chooser_called();
                    });
                };

                menu_box.pack_start(bookmark_label, false, false);
                menu_box.pack_start(bookmark_box, false, false);
                menu_box.pack_start(playlist_label, false, false);
                menu_box.pack_start(playlist_box, false, false);
                menu_box.pack_start(directory_chooser, false, false);
            }

            add(menu_box);
        }

        public void add_bookmark(string file_path) {
            string bookmark_name = File.new_for_path(file_path).get_basename();
            var box1 = new Box(Orientation.HORIZONTAL, 0);
            {
                var new_menu_item = new Button();
                {
                    var box2 = new Box(Orientation.HORIZONTAL, 0);
                    {
                        var image = new Image.from_icon_name(IconName.FOLDER, IconSize.SMALL_TOOLBAR);
                        var label = new Label(bookmark_name);
                        box2.pack_start(image, false, false);
                        box2.pack_start(label, false, false);
                    }
                    new_menu_item.add(box2);
                    new_menu_item.relief = ReliefStyle.NONE;
                    new_menu_item.clicked.connect(() => {
                        bookmark_directory_selected(file_path);
                    });
                }

                var new_del_button = new Button.from_icon_name(IconName.LIST_REMOVE);
                {
                    new_del_button.relief = ReliefStyle.NONE;
                    new_del_button.tooltip_text = _("Delete the bookmark \"%s\"").printf(bookmark_name);
                    new_del_button.clicked.connect(() => {
                        if (bookmark_del_button_clicked(file_path)) {
                            bookmark_box.remove(bookmark_buttons[file_path]);
                            bookmark_buttons.unset(file_path);
                        }
                    });
                }

                box1.pack_start(new_menu_item, true, true);
                box1.pack_start(new_del_button ,false, false);
                box1.show_all();
            }

            bookmark_box.pack_start(box1, false, false);
            bookmark_buttons[file_path] = box1;
        }

        public bool has_bookmark(string bookmark_path) {
            return bookmark_buttons.has_key(bookmark_path);
        }

        public void remove_bookmark(string bookmark_path) {
            if (bookmark_buttons.has_key(bookmark_path)) {
                var button = bookmark_buttons[bookmark_path];
                bookmark_box.remove(button);
                bookmark_buttons.unset(bookmark_path);
            }
        }

        public Gee.List<string> get_bookmarks() {
            Gee.List<string> result = new Gee.ArrayList<string>();
            foreach (var key in bookmark_buttons.keys) {
                result.add(key);
            }
            return result;
        }

        public bool has_playlist(string playlist_name) {
            return playlist_buttons.has_key(playlist_name);
        }

        public void add_playlist(string playlist_name, string playlist_path) {
            var box1 = new Box(Orientation.HORIZONTAL, 0);
            {
                var new_menu_item = new Button();
                {
                    var box2 = new Box(Orientation.HORIZONTAL, 0);
                    {
                        var image = new Image.from_icon_name(IconName.AUDIO_FILE, IconSize.SMALL_TOOLBAR);
                        var label = new Label(playlist_name);
                        box2.pack_start(image, false, false);
                        box2.pack_start(label, false, false);
                    }
                    new_menu_item.add(box2);
                    new_menu_item.relief = ReliefStyle.NONE;
                    new_menu_item.clicked.connect(() => {
                        playlist_selected(playlist_name, playlist_path);
                    });
                }

                var new_del_button = new Button.from_icon_name(IconName.LIST_REMOVE, IconSize.SMALL_TOOLBAR);
                {
                    new_del_button.relief = ReliefStyle.NONE;
                    new_del_button.tooltip_text = _("Delete the playlist \"%s\"").printf(playlist_name);
                    new_del_button.clicked.connect(() => {
                        if (playlist_del_button_clicked(playlist_path)) {
                            playlist_box.remove(playlist_buttons[playlist_name]);
                            playlist_paths.unset(playlist_name);
                            playlist_buttons.unset(playlist_name);
                        }
                    });
                }

                box1.pack_start(new_menu_item, true, true);
                box1.pack_start(new_del_button, false, false);
                box1.show_all();
            }

            playlist_box.pack_start(box1, false, false);
            playlist_paths[playlist_name] = playlist_path;
            playlist_buttons[playlist_name] = box1;
        }

        public void remove_bookmark_all() {
            foreach (var key in bookmark_buttons.keys) {
                bookmark_box.remove(bookmark_buttons[key]);
                bookmark_buttons.unset(key);
            }
        }

        public void remove_playlist_all() {
            foreach (var key in playlist_buttons.keys) {
                playlist_box.remove(playlist_buttons[key]);
                playlist_buttons.unset(key);
                playlist_paths.unset(key);
            }
        }
    }
}
