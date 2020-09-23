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
        public abstract void add_bookmark(string file_path);
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
        private TreeView bookmark_tree;
        private unowned TreeIter? playlist_root;
        private unowned TreeIter? bookmark_root;
        
        public Sidebar() {
            var frame = new Frame(null);
            {
                var bookmark_scrolled = new ScrolledWindow(null, null);
                {
                    bookmark_tree = new TreeView();
                    {
                        TreeStore bookmark_store = new TreeStore(5, typeof(string), typeof(string), typeof(string),
                                                                 typeof(MenuType), typeof(string));
                        {
                            bookmark_store.append(out bookmark_root, null);
                            bookmark_store.set(bookmark_root,
                                               0, IconName.Symbolic.USER_BOOKMARKS, 1, Text.MENU_BOOKMARK,
                                               2, "", 3, MenuType.BOOKMARK, 4, "");

                            TreeIter bm_iter;
                            bookmark_store.append(out playlist_root, null);
                            bookmark_store.set(playlist_root,
                                               0, IconName.Symbolic.MEDIA_OPTICAL, 1, Text.MENU_PLAYLIST,
                                               2, "", 3, MenuType.PLAYLIST_HEADER, 4, "");
                            bookmark_store.append(out bm_iter, null);
                            bookmark_store.set(bm_iter, 0, null, 1, null, 2, null,
                                               3, MenuType.SEPARATOR, 4, "");
                            bookmark_store.append(out bm_iter, null);
                            bookmark_store.set(bm_iter, 0, IconName.Symbolic.FOLDER_OPEN, 1, Text.MENU_CHOOSE_DIR,
                                               2, null, 3, MenuType.CHOOSER, 4, "");
                        }

                        TreeViewColumn bookmark_title_col = new TreeViewColumn();
                        {
                            var bookmark_icon_cell = new CellRendererPixbuf();
                            var bookmark_label_cell = new CellRendererText();
                            {
                                bookmark_label_cell.family = Text.FONT_FAMILY;
                                bookmark_label_cell.language = Environ.get_variable(Environ.get(), "LANG");
                            }

                            bookmark_title_col.pack_start(bookmark_icon_cell, false);
                            bookmark_title_col.pack_start(bookmark_label_cell, true);
                            bookmark_title_col.add_attribute(bookmark_icon_cell, "icon-name", 0);
                            bookmark_title_col.add_attribute(bookmark_label_cell, "text", 1);
                            bookmark_title_col.set_title("label");
                            bookmark_title_col.sizing = TreeViewColumnSizing.AUTOSIZE;
                        }

                        TreeViewColumn bookmark_del_col = new TreeViewColumn();
                        {
                            var bookmark_del_cell = new CellRendererPixbuf();

                            bookmark_del_col.pack_start(bookmark_del_cell, false);
                            bookmark_del_col.add_attribute(bookmark_del_cell, "icon-name", 4);
                            bookmark_del_col.set_title("del");
                        }

                        bookmark_tree.activate_on_single_click = true;
                        bookmark_tree.headers_visible = false;
                        bookmark_tree.hover_selection = true;
                        bookmark_tree.reorderable = false;
                        bookmark_tree.show_expanders = true;
                        bookmark_tree.enable_tree_lines = false;
                        bookmark_tree.level_indentation = 0;

                        bookmark_tree.set_model(bookmark_store);
                        bookmark_tree.insert_column(bookmark_del_col, 1);
                        bookmark_tree.insert_column(bookmark_title_col, 0);

                        bookmark_tree.set_row_separator_func((model, iter) => {
                                Value menu_type;
                                model.get_value(iter, 3, out menu_type);
                                return ((MenuType) menu_type == MenuType.SEPARATOR);
                            });

                        bookmark_tree.get_selection().changed.connect(() => {
                                TreeSelection bookmark_selection = bookmark_tree.get_selection();
                                TreeStore? temp_store = bookmark_tree.model as TreeStore;

                                temp_store.foreach((model, path, iter) => {
                                        Value type;
                                        temp_store.get_value(iter, 3, out type);
                                        if ((MenuType) type == MenuType.FOLDER || (MenuType) type == MenuType.PLAYLIST_NAME) {
                                            string icon_name = "";
                                            if (bookmark_selection.iter_is_selected(iter)) {
                                                icon_name = IconName.Symbolic.LIST_REMOVE;
                                            } else {
                                                icon_name = "";
                                            }
                                            temp_store.set_value(iter, 4, icon_name);
                                        }
                                        return false;
                                    });
                            });

                        bookmark_tree.row_activated.connect((path, column) => {
                                Value dir_path;
                                Value bookmark_name;
                                TreeIter bm_iter;

                                debug("bookmark_tree_row_activated.");
                                bookmark_tree.model.get_iter(out bm_iter, path);
                                bookmark_tree.model.get_value(bm_iter, 3, out bookmark_name);

                                switch ((MenuType) bookmark_name) {
                                case MenuType.BOOKMARK:
                                    if (bookmark_tree.is_row_expanded(path)) {
                                        bookmark_tree.collapse_row(path);
                                    } else {
                                        bookmark_tree.expand_row(path, false);
                                    }
                                    break;
                                
                                case MenuType.FOLDER:
                                    bookmark_tree.model.get_value(bm_iter, 2, out dir_path);

                                    if (column.get_title() != "del") {
                                        bookmark_directory_selected((string) dir_path);
                                    } else {
                                        if (bookmark_del_button_clicked((string) dir_path)) {
                                            TreeStore? store = bookmark_tree.model as TreeStore;
                                            if (store != null) {
                                                store.remove(ref bm_iter);
                                            }
                                        }
                                    }
                                    break;
                                case MenuType.PLAYLIST_HEADER:
                                    if (bookmark_tree.is_row_expanded(path)) {
                                        bookmark_tree.collapse_row(path);
                                    } else {
                                        bookmark_tree.expand_row(path, false);
                                    }
                                    break;
                                case MenuType.PLAYLIST_NAME:
                                    Value val1;
                                    Value val2;
                                    bookmark_tree.model.get_value(bm_iter, 1, out val1);
                                    bookmark_tree.model.get_value(bm_iter, 2, out val2);
                                    string playlist_name = (string) val1;
                                    string playlist_path = (string) val2;

                                    if (column.get_title() != "del") {
                                        playlist_selected(playlist_name, playlist_path);
                                    } else {
                                        if (playlist_del_button_clicked(playlist_path)) {
                                            TreeStore? temp_store = bookmark_tree.model as TreeStore;
                                            if (temp_store != null) {
                                                temp_store.remove(ref bm_iter);
                                            }
                                        }
                                    }
                                    break;
                                case MenuType.CHOOSER:
                                    file_chooser_called();
                                    break;
                                }
                            });

                        bookmark_tree.expand_all();
                    }

                    bookmark_scrolled.shadow_type = ShadowType.NONE;
                    bookmark_scrolled.hscrollbar_policy = PolicyType.NEVER;
                    bookmark_scrolled.add(bookmark_tree);
                }

                frame.set_shadow_type(ShadowType.NONE);
                frame.get_style_context().add_class(StyleClass.SIDEBAR);
                frame.add(bookmark_scrolled);
            }

            add(frame);
        }

        public void add_bookmark(string file_path) {
            File file = File.new_for_path(file_path);
            string file_name = file.get_basename();
            TreeStore? temp_store = bookmark_tree.model as TreeStore;
            bookmark_added(file_path);
            TreeIter temp_iter;
            temp_store.append(out temp_iter, bookmark_root);
            temp_store.set(temp_iter,
                           0, IconName.Symbolic.FOLDER,
                           1, file_name,
                           2, file_path,
                           3, MenuType.FOLDER,
                           4, Text.EMPTY);
        }

        public bool has_playlist(string playlist_name) {
            TreeStore store = bookmark_tree.model as TreeStore;
            if(store.iter_has_child(playlist_root)) {
                TreeIter iter;
                store.iter_children(out iter, playlist_root);
                do {
                    Value val;
                    store.get_value(iter, 1, out val);
                    string val_name = (string) val;
                    if (val_name == playlist_name) {
                        return true;
                    }
                } while (store.iter_next(ref iter));
            }
            return false;
        }
        
        public void add_playlist(string playlist_name, string playlist_path) {
            TreeStore? temp_store = bookmark_tree.model as TreeStore;
            TreeIter temp_iter;
            temp_store.append(out temp_iter, playlist_root);
            temp_store.set(temp_iter,
                           0, IconName.Symbolic.AUDIO_FILE,
                           1, playlist_name,
                           2, playlist_path,
                           3, MenuType.PLAYLIST_NAME,
                           4, Text.EMPTY);
        }

        public void remove_bookmark_all() {
            TreeIter bm_iter;
            TreeStore? bookmark_store = (TreeStore) bookmark_tree.model;
            bookmark_store.iter_children(out bm_iter, bookmark_root);

            while (bookmark_store.iter_is_valid(bm_iter)) {
                bookmark_store.remove(ref bm_iter);
            }
        }

        public void remove_playlist_all() {
            TreeIter bm_iter;
            TreeStore? bookmark_store = (TreeStore) bookmark_tree.model;
            bookmark_store.iter_children(out bm_iter, playlist_root);

            while (bookmark_store.iter_is_valid(bm_iter)) {
                bookmark_store.remove(ref bm_iter);
            }
        }
    }
}
