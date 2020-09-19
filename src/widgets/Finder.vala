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

namespace Tatam {
    public class Finder : Bin {
        public class Builder {
            public Gdk.Pixbuf parent_pixbuf_value;
            public Gdk.Pixbuf folder_pixbuf_value;
            public Gdk.Pixbuf file_pixbuf_value;
            public Gdk.Pixbuf cd_pixbuf_value;

            public Builder parent_pixbuf(Gdk.Pixbuf pixbuf) {
                this.parent_pixbuf_value = pixbuf;
                return this;
            }

            public Builder folder_pixbuf(Gdk.Pixbuf pixbuf) {
                this.folder_pixbuf_value = pixbuf;
                return this;
            }

            public Builder file_pixbuf(Gdk.Pixbuf pixbuf) {
                this.file_pixbuf_value = pixbuf;
                return this;
            }

            public Builder disc_pixbuf(Gdk.Pixbuf pixbuf) {
                this.cd_pixbuf_value = pixbuf;
                return this;
            }

            public Finder build() {
                return new Finder(this);
            }
        }

        const int max_icon_size = 256;

        private int count;
        private IconTheme icon_theme;
        private int zoom_level;
        private ScrolledWindow finder_container;
        private FlowBox finder;
        private ProgressBar progress;
        private Revealer progress_revealer;
        private Label while_label;

        private Gee.List<Tatam.FileInfo?> file_info_list;

        public bool use_popover { get; set; }
        public string dir_path { get; set; }
        public bool activate_on_single_click { get; set; }

        public signal void dir_changed(string dir_path);
        public signal void bookmark_button_clicked(string file_path);
        public signal void add_button_clicked(string file_path);
        public signal void play_button_clicked(string file_path);
        public signal void icon_image_resized(int icon_size);
        public signal void file_button_clicked(string file_path);

        public static Finder create_default_instance() {
            try {
                IconTheme icon_theme = Gtk.IconTheme.get_default();
                return new Finder.Builder()
                .file_pixbuf(icon_theme.load_icon(IconName.AUDIO_FILE, max_icon_size, 0))
                .disc_pixbuf(icon_theme.load_icon(IconName.MEDIA_OPTICAL, max_icon_size, 0))
                .folder_pixbuf(icon_theme.load_icon(IconName.FOLDER_MUSIC, max_icon_size, 0))
                .parent_pixbuf(icon_theme.load_icon(IconName.GO_UP, max_icon_size, 0))
                .build();
            } catch (GLib.Error e) {
                stderr.printf(Text.ERROR_LOAD_ICON);
                Process.exit(1);
            }
        }
        
        private Finder(Builder builder) {
            debug("creating finder start");
            zoom_level = 9;
            count = 0;
            activate_on_single_click = true;
            icon_theme = Gtk.IconTheme.get_default();
            FinderItem.file_pixbuf = builder.file_pixbuf_value;
            FinderItem.cd_pixbuf = builder.cd_pixbuf_value;
            FinderItem.folder_pixbuf = builder.folder_pixbuf_value;
            FinderItem.parent_pixbuf = builder.parent_pixbuf_value;
            var overlay_while_label = new Overlay();
            {
                var finder_box = new Box(Orientation.VERTICAL, 1);
                {
                    finder_container = new ScrolledWindow(null, null);
                    {
                        finder_container.get_style_context().add_class(StyleClass.VIEW);
                    }

                    progress_revealer = new Revealer();
                    {
                        progress = new ProgressBar();
                        {
                            progress.show_text = false;
                        }

                        progress_revealer.reveal_child = false;
                        progress_revealer.transition_type = RevealerTransitionType.SLIDE_DOWN;
                        progress_revealer.valign = Align.START;
                        progress_revealer.add(progress);
                    }
            
                    finder_box.pack_start(progress_revealer, false, false);
                    finder_box.pack_start(finder_container, true, true);
                }
            
                var while_label_box = new Box(Orientation.VERTICAL, 4);
                {
                    while_label = new Label("");
                    {
                        while_label.margin = 4;
                    }

                    while_label_box.pack_start(while_label);
                    while_label_box.hexpand = false;
                    while_label_box.vexpand = false;
                    while_label_box.halign = Align.START;
                    while_label_box.valign = Align.END;
                    while_label_box.get_style_context().add_class(StyleClass.WHILE_LABEL);
                }
            
                overlay_while_label.add(finder_box);
                overlay_while_label.add_overlay(while_label_box);
            }

            add(overlay_while_label);

            debug("creating finder end");
        }

        public async void change_dir(string dir_path) {
            this.dir_path = dir_path;
            change_cursor(Gdk.CursorType.WATCH);
            while_label.visible = true;
            while_label.label = Text.FINDER_LOAD_FILES;
            int size = get_level_size();
            progress.set_fraction(0.0);
            progress_revealer.reveal_child = true;

            var thread = new Thread<Gee.List<Tatam.FileInfo?>>(null, () => {
                    Gee.List<Tatam.FileInfo?> result_list = Tatam.Files.get_file_info_list_in_dir(dir_path);
                    Idle.add(change_dir.callback);
                    return result_list;
                });
            yield;
            file_info_list = thread.join();
            
            if (finder != null) {
                finder_container.remove(finder.get_parent());
                finder = null;
            }

            finder = new FlowBox();
            finder.max_children_per_line = 100;
            finder.min_children_per_line = 1;
            finder.row_spacing = 0;
            finder.column_spacing = 0;
            finder.homogeneous = true;
            finder.selection_mode = SelectionMode.NONE;
            finder.halign = Align.START;
            finder.valign = Align.START;
            finder_container.add(finder);

            int i = 0;
            
            foreach (Tatam.FileInfo file_info in this.file_info_list) {
                if (file_info.name == "..") {
                    continue;
                }

                if (file_info.name != "..") {
                    while_label.label = Text.FILE_LOADED.printf(file_info.name);
                }

                if (file_info.type == Tatam.FileType.DIRECTORY) {
                    try {
                        file_info.type = Tatam.Files.get_file_type(file_info.path);
                    } catch (FileError e) {
                        stderr.printf(Text.ERROR_OPEN_FILE.printf(file_info.path));
                        break;
                    }
                }

                var item_widget = new FinderItem(file_info, size, use_popover);
                {
                    switch (file_info.type) {
                    case Tatam.FileType.DIRECTORY:
                    case Tatam.FileType.DISC:
                        item_widget.clicked.connect(() => {
                                change_dir.begin(file_info.path);
                                file_button_clicked(file_info.path);
                            });
                        item_widget.bookmark_button_clicked.connect((file_path) => {
                                bookmark_button_clicked(file_path);
                            });
                        break;

                    case Tatam.FileType.PARENT:
                        item_widget.clicked.connect(() => {
                                change_dir.begin(file_info.path);
                                file_button_clicked(file_info.path);
                            });
                        break;

                    case Tatam.FileType.FILE:
                        item_widget.clicked.connect(() => {
                                play_button_clicked(file_info.path);
                            });
                        break;
                    }

                    item_widget.add_button_clicked.connect((file_path) => {
                            add_button_clicked(file_path);
                        });

                    item_widget.play_button_clicked.connect((file_path) => {
                            play_button_clicked(file_path);
                        });
                }

                finder.add(item_widget);
                
                double fraction = (double) i + 1 / (double) file_info_list.size;
                progress.fraction = fraction;

                finder_container.show_all();
                for (int j = 0; j < file_info_list.size; j++) {
                    var finder_item = finder.get_child_at_index(j) as FinderItem;
                    if (finder_item != null) {
                        finder_item.hide_buttons();
                    }
                }

                Idle.add(change_dir.callback);
                yield;

                i++;
            }

            change_cursor(Gdk.CursorType.LEFT_PTR);
            while_label.visible = false;
            progress_revealer.reveal_child = false;
            dir_changed(dir_path);
        }

        public void set_default_icon_size(int icon_size) {
            zoom_level = get_size_level(icon_size);
        }
        
        public void change_cursor(Gdk.CursorType cursor_type) {
            finder_container.get_parent_window().set_cursor(
                new Gdk.Cursor.for_display(Gdk.Screen.get_default().get_display(), cursor_type));
        }

        public void hide_while_label() {
            while_label.visible = false;
        }

        public void zoom_out() {
            if (zoom_level > 1) {
                zoom_level--;
                int size = get_level_size();
                int i = 0;
                FinderItem? item = null;
                do {
                    item = (FinderItem)finder.get_child_at_index(i);
                    if (item != null) {
                        item.set_image_size(size);
                        i++;
                    }
                } while (item != null);
                icon_image_resized(size);
            }
        }

        public void zoom_in() {
            if (zoom_level < 10) {
                zoom_level++;
                int size = get_level_size();
                int i = 0;
                FinderItem? item = null;
                do {
                    item = (FinderItem)finder.get_child_at_index(i);
                    if (item != null) {
                        item.set_image_size(size);
                        i++;
                    }
                } while (item != null);
                icon_image_resized(size);
            }
        }

        private int get_level_size() {
            switch (zoom_level) {
            case 1: return 32;
            case 2: return 36;
            case 3: return 42;
            case 4: return 48;
            case 5: return 52;
            case 6: return 64;
            case 7: return 72;
            case 8: return 96;
            case 9: return 128;
            case 10: return 196;
            default: return 128;
            }
        }

        private int get_size_level(int size) {
            if (size >= 0) {
                if (size < 36) {
                    return 1;
                } else if (size < 42) {
                    return 2;
                } else if (size < 48) {
                    return 3;
                } else if (size < 52) {
                    return 4;
                } else if (size < 64) {
                    return 5;
                } else if (size < 72) {
                    return 6;
                } else if (size < 96) {
                    return 7;
                } else if (size < 128) {
                    return 8;
                } else if (size < 196) {
                    return 9;
                } else {
                    return 10;
                }
            } else {
                return 8;
            }
        }
    }
}
