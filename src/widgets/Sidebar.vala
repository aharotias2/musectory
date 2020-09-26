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

    public class Sidebar : Frame, SidebarInterface {
        private ScrolledWindow sidebar_scroll;
        private TreeView sidebar_tree;
        private TreeStore sidebar_store;
        private TreeIter? playlist_root;
        private TreeIter? bookmark_root;

        public int max_width {
            get {
                return sidebar_scroll.max_content_width;
            }
            set {
                sidebar_scroll.max_content_width = value;
            }
        }
        
        public int min_width {
            get {
                return sidebar_scroll.min_content_width;
            }
            set {
                int w1 = value;
                int w2, w3;
                sidebar_tree.get_preferred_width(out w2, out w3);
                if (w1 < w3) {
                    sidebar_scroll.min_content_width = w1;
                } else {
                    sidebar_scroll.min_content_width = w3;
                }
            }
        }
        
        public int max_height {
            get {
                return sidebar_scroll.max_content_height;
            }
            set {
                sidebar_scroll.max_content_height = value;
            }
        }
        
        public int min_height {
            get {
                return sidebar_scroll.min_content_height;
            }
            set {
                int w1 = value;
                int w2, w3;
                sidebar_tree.get_preferred_height(out w2, out w3);
                if (w1 < w3) {
                    sidebar_scroll.min_content_height = w1;
                } else {
                    sidebar_scroll.min_content_height = w3;
                }
            }
        }
        
        public Sidebar() {
            sidebar_scroll = new ScrolledWindow(null, null);
            {
                sidebar_tree = new TreeView();
                {
                    sidebar_store = new TreeStore(5,
                                                  typeof(string),
                                                  typeof(string),
                                                  typeof(string),
                                                  typeof(MenuType),
                                                  typeof(string));

                    var sidebar_title_col = new TreeViewColumn();
                    {
                        var sidebar_icon_cell = new CellRendererPixbuf();
                        var sidebar_label_cell = new CellRendererText();
                        {
                            sidebar_label_cell.family = Text.FONT_FAMILY;
                            sidebar_label_cell.language = Environ.get_variable(Environ.get(), "LANG");
                        }

                        sidebar_title_col.pack_start(sidebar_icon_cell, false);
                        sidebar_title_col.add_attribute(sidebar_icon_cell, "icon-name", 0);

                        sidebar_title_col.pack_start(sidebar_label_cell, true);
                        sidebar_title_col.add_attribute(sidebar_label_cell, "text", 1);

                        sidebar_title_col.set_title("label");
                        sidebar_title_col.sizing = TreeViewColumnSizing.AUTOSIZE;
                    }

                    var sidebar_del_col = new TreeViewColumn();
                    {
                        var sidebar_del_cell = new CellRendererPixbuf();

                        sidebar_del_col.pack_start(sidebar_del_cell, false);
                        sidebar_del_col.add_attribute(sidebar_del_cell, "icon-name", 4);
                        sidebar_del_col.set_title("del");
                    }

                    sidebar_tree.set_model(sidebar_store);
                    sidebar_tree.append_column(sidebar_title_col);
                    sidebar_tree.append_column(sidebar_del_col);
                    sidebar_tree.activate_on_single_click = true;
                    sidebar_tree.headers_visible = false;
                    sidebar_tree.hover_selection = true;
                    sidebar_tree.reorderable = false;
                    sidebar_tree.show_expanders = true;
                    sidebar_tree.enable_tree_lines = false;
                    sidebar_tree.level_indentation = 0;

                    sidebar_tree.set_row_separator_func((model, iter) => {
                            Value menu_type;
                            model.get_value(iter, 3, out menu_type);
                            return ((MenuType) menu_type == MenuType.SEPARATOR);
                        });

                    sidebar_tree.get_selection().changed.connect(() => {
                            TreeSelection sidebar_selection = sidebar_tree.get_selection();
                            sidebar_store.foreach((model, path, iter) => {
                                    Value type;
                                    sidebar_store.get_value(iter, 3, out type);
                                    if ((MenuType) type == MenuType.FOLDER || (MenuType) type == MenuType.PLAYLIST_NAME) {
                                        string icon_name = "";
                                        if (sidebar_selection.iter_is_selected(iter)) {
                                            icon_name = IconName.LIST_REMOVE;
                                        } else {
                                            icon_name = "";
                                        }
                                        sidebar_store.set_value(iter, 4, icon_name);
                                    }
                                    return false;
                                });
                        });

                    sidebar_tree.row_activated.connect((path, column) => {
                            Value dir_path;
                            Value sidebar_name;
                            TreeIter bm_iter;

                            debug("sidebar_tree_row_activated.");
                            sidebar_tree.model.get_iter(out bm_iter, path);
                            sidebar_tree.model.get_value(bm_iter, 3, out sidebar_name);

                            switch ((MenuType) sidebar_name) {
                            case MenuType.BOOKMARK:
                                if (sidebar_tree.is_row_expanded(path)) {
                                    sidebar_tree.collapse_row(path);
                                } else {
                                    sidebar_tree.expand_row(path, false);
                                }
                                break;
                                
                            case MenuType.FOLDER:
                                sidebar_tree.model.get_value(bm_iter, 2, out dir_path);

                                if (column.get_title() != "del") {
                                    bookmark_directory_selected((string) dir_path);
                                } else {
                                    if (bookmark_del_button_clicked((string) dir_path)) {
                                        if (sidebar_store != null) {
                                            sidebar_store.remove(ref bm_iter);
                                        }
                                    }
                                }
                                break;

                            case MenuType.PLAYLIST_HEADER:
                                if (sidebar_tree.is_row_expanded(path)) {
                                    sidebar_tree.collapse_row(path);
                                } else {
                                    sidebar_tree.expand_row(path, false);
                                }
                                break;

                            case MenuType.PLAYLIST_NAME:
                                Value val1;
                                Value val2;
                                sidebar_tree.model.get_value(bm_iter, 1, out val1);
                                sidebar_tree.model.get_value(bm_iter, 2, out val2);
                                string playlist_name = (string) val1;
                                string playlist_path = (string) val2;

                                if (column.get_title() != "del") {
                                    playlist_selected(playlist_name, playlist_path);
                                } else {
                                    if (playlist_del_button_clicked(playlist_path)) {
                                        sidebar_store.remove(ref bm_iter);
                                    }
                                }
                                break;

                            case MenuType.CHOOSER:
                                file_chooser_called();
                                break;
                            }
                        });

                    sidebar_tree.expand_all();
                }

                sidebar_scroll.add(sidebar_tree);
                sidebar_scroll.hscrollbar_policy = PolicyType.AUTOMATIC;
                sidebar_scroll.vscrollbar_policy = PolicyType.AUTOMATIC;
            }
            
            add(sidebar_scroll);
            init_store();
        }

        public void init_store() {
            TreeIter bookmark_root;
            TreeIter playlist_root;
            sidebar_store.append(out bookmark_root, null);
            sidebar_store.set(bookmark_root,
                              0, IconName.USER_BOOKMARKS,
                              1, Text.MENU_BOOKMARK,
                              2, "",
                              3, MenuType.BOOKMARK,
                              4, "");
            this.bookmark_root = bookmark_root;
            TreeIter bm_iter;
            sidebar_store.append(out playlist_root, null);
            sidebar_store.set(playlist_root,
                              0, IconName.MEDIA_OPTICAL,
                              1, Text.MENU_PLAYLIST,
                              2, "",
                              3, MenuType.PLAYLIST_HEADER,
                              4, "");
            sidebar_store.append(out bm_iter, null);
            sidebar_store.set(bm_iter,
                              0, null,
                              1, null,
                              2, null,
                              3, MenuType.SEPARATOR,
                              4, "");
            sidebar_store.append(out bm_iter, null);
            sidebar_store.set(bm_iter,
                              0, IconName.FOLDER_OPEN,
                              1, Text.MENU_CHOOSE_DIR,
                              2, null,
                              3, MenuType.CHOOSER,
                              4, "");
            this.playlist_root = playlist_root;
            sidebar_tree.expand_all();
        }
        
        public void add_bookmark(string file_path) {
            File file = File.new_for_path(file_path);
            string file_name = file.get_basename();
            bookmark_added(file_path);
            TreeIter temp_iter;
            sidebar_store.append(out temp_iter, bookmark_root);
            sidebar_store.set(temp_iter,
                              0, IconName.FOLDER,
                              1, file_name,
                              2, file_path,
                              3, MenuType.FOLDER,
                              4, Text.EMPTY);
            sidebar_tree.expand_all();
        }

        public void remove_bookmark(string bookmark_path) {
            if (sidebar_store.iter_has_child(bookmark_root)) {
                TreeIter iter;
                sidebar_store.iter_children(out iter, bookmark_root);
                do {
                    Value val;
                    sidebar_store.get_value(iter, 2, out val);
                    string val_path = (string) val;
                    if (bookmark_path == val_path) {
                        sidebar_store.remove(ref iter);
                        break;
                    }
                } while (sidebar_store.iter_next(ref iter));
            }
        }
        
        public Gee.List<string> get_bookmarks() {
            Gee.List<string> bookmark_list = new Gee.ArrayList<string>();
            if (sidebar_store.iter_has_child(bookmark_root)) {
                debug(".");
                TreeIter iter;
                sidebar_store.iter_children(out iter, bookmark_root);
                do {
                    debug("..");
                    Value val;
                    sidebar_store.get_value(iter, 2, out val);
                    string bookmarked_path = (string) val;
                    bookmark_list.add(bookmarked_path);
                } while (sidebar_store.iter_next(ref iter));
            }
            debug(".");
            return bookmark_list;
        }

        public bool has_bookmark(string bookmark_path) {
            if (sidebar_store.iter_has_child(bookmark_root)) {
                TreeIter iter;
                sidebar_store.iter_children(out iter, bookmark_root);
                do {
                    Value val;
                    sidebar_store.get_value(iter, 2, out val);
                    string val_path = val.get_string();
                    if (val_path == bookmark_path) {
                        return true;
                    }
                } while (sidebar_store.iter_next(ref iter));
            }
            return false;
        }
        
        public bool has_playlist(string playlist_name) {
            if (sidebar_store.iter_has_child(playlist_root)) {
                TreeIter iter;
                sidebar_store.iter_children(out iter, playlist_root);
                do {
                    Value val;
                    sidebar_store.get_value(iter, 1, out val);
                    string val_name = val.get_string();
                    if (val_name == playlist_name) {
                        return true;
                    }
                } while (sidebar_store.iter_next(ref iter));
            }
            return false;
        }
        
        public void add_playlist(string playlist_name, string playlist_path) {
            TreeIter temp_iter;
            sidebar_store.append(out temp_iter, playlist_root);
            sidebar_store.set(temp_iter,
                              0, IconName.AUDIO_FILE,
                              1, playlist_name,
                              2, playlist_path,
                              3, MenuType.PLAYLIST_NAME,
                              4, Text.EMPTY);
            sidebar_tree.expand_all();
        }

        public void remove_bookmark_all() {
            TreeIter bm_iter;
            sidebar_store.iter_children(out bm_iter, bookmark_root);
            while (sidebar_store.iter_is_valid(bm_iter)) {
                sidebar_store.remove(ref bm_iter);
            }
        }

        public void remove_playlist_all() {
            TreeIter bm_iter;
            sidebar_store.iter_children(out bm_iter, playlist_root);
            while (sidebar_store.iter_is_valid(bm_iter)) {
                sidebar_store.remove(ref bm_iter);
            }
        }
    }
}
