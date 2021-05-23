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

namespace Moegi {
    public class Finder : Bin {
        public signal void dir_selected(string dir_path);
        public signal void dir_changed(string dir_path);
        public signal void bookmark_button_clicked(string file_path);
        public signal void add_button_clicked(string file_path);
        public signal void play_button_clicked(string file_path);
        public signal void icon_image_resized(int icon_size);
        public signal void file_button_clicked(string file_path);

        public Gdk.Pixbuf parent_pixbuf_value { get; construct set; }
        public Gdk.Pixbuf folder_pixbuf_value { get; construct set; }
        public Gdk.Pixbuf file_pixbuf_value { get; construct set; }
        public Gdk.Pixbuf cd_pixbuf_value { get; construct set; }
        public string dir_path { get; set; }
        public bool activate_on_single_click { get; set; }

        const int MAX_ICON_SIZE = 256;

        private int count;
        private IconTheme icon_theme;
        private int zoom_level;
        private ScrolledWindow finder_container;
        private FlowBox finder;
        private ProgressBar progress;
        private Revealer progress_revealer;
        private Label empty_dir_label;
        private Stack finder_stack;
        private Gee.List<Moegi.FileInfo?> file_info_list;

        public Finder() {
            try {
                IconTheme icon_theme = Gtk.IconTheme.get_default();
                Object(
                   file_pixbuf_value: icon_theme.load_icon(IconName.AUDIO_FILE, MAX_ICON_SIZE, 0),
                   cd_pixbuf_value: icon_theme.load_icon(IconName.MEDIA_OPTICAL, MAX_ICON_SIZE, 0),
                   folder_pixbuf_value: icon_theme.load_icon(IconName.FOLDER_MUSIC, MAX_ICON_SIZE, 0),
                   parent_pixbuf_value: icon_theme.load_icon(IconName.GO_UP, MAX_ICON_SIZE, 0)
               );
            } catch (GLib.Error e) {
                stderr.printf(_("icon file can not load.\n"));
                Process.exit(1);
            }
        }

        construct {
            debug("creating finder start");
            zoom_level = 9;
            count = 0;
            activate_on_single_click = true;
            icon_theme = Gtk.IconTheme.get_default();
            FinderItem.file_pixbuf = file_pixbuf_value;
            FinderItem.cd_pixbuf = cd_pixbuf_value;
            FinderItem.folder_pixbuf = folder_pixbuf_value;
            FinderItem.parent_pixbuf = parent_pixbuf_value;
            finder_stack = new Stack();
            {
                var overlay_progress = new Overlay();
                {
                    finder_container = new ScrolledWindow(null, null);
                    {
                        finder_container.get_style_context().add_class(StyleClass.VIEW);
                    }

                    var progress_box = new Box(Orientation.VERTICAL, 0);
                    {
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

                        progress_box.pack_start(progress_revealer, false, false);
                    }

                    overlay_progress.add(finder_container);
                    overlay_progress.add_overlay(progress_box);
                    overlay_progress.set_overlay_pass_through(progress_box, true);
                }

                empty_dir_label = new Label(_("This directory is empty"));

                finder_stack.add_named(overlay_progress, "not-empty");
                finder_stack.add_named(empty_dir_label, "empty");
                finder_stack.visible_child_name = "empty";
            }

            add(finder_stack);

            debug("creating finder end");
        }

        public async void change_dir(string dir_path) {
            this.dir_path = dir_path;
            int counter_holder = ++count;
            change_cursor(Gdk.CursorType.WATCH);
            int size = get_level_size();
            progress.set_fraction(0.0);
            progress_revealer.reveal_child = true;
            dir_selected(dir_path);

            var thread = new Thread<Gee.List<Moegi.FileInfo?> >(null, () => {
                Gee.List<Moegi.FileInfo?> result_list = Moegi.Files.get_file_info_list_in_dir(dir_path);
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

            if (file_info_list.size == 0) {
                finder_stack.visible_child_name = "empty";
            } else {
                finder_stack.visible_child_name = "not-empty";
            }

            int i = 0;

            finder_container.show_all();

            Idle.add(change_dir.callback);
            yield;

            foreach (Moegi.FileInfo file_info in this.file_info_list) {
                if (file_info.name == "..") {
                    continue;
                }

                if (file_info.type == Moegi.FileType.DIRECTORY) {
                    try {
                        file_info.type = Moegi.Files.get_file_type(file_info.path);
                    } catch (FileError e) {
                        stderr.printf(_("FileError catched with file_info.path '%s' which is cannot open\n").printf(file_info.path));
                        break;
                    }
                }

                var item_widget = new FinderItem(file_info, size);
                {
                    switch (file_info.type) {
                      case Moegi.FileType.DIRECTORY:
                      case Moegi.FileType.DISC:
                        item_widget.clicked.connect(() => {
                            change_dir.begin(file_info.path);
                            file_button_clicked(file_info.path);
                        });
                        item_widget.bookmark_button_clicked.connect((file_path) => {
                            bookmark_button_clicked(file_path);
                        });
                        break;

                      case Moegi.FileType.FILE:
                        item_widget.clicked.connect(() => {
                            play_button_clicked(file_info.path);
                        });
                        break;

                    default:
                        break;
                    }

                    item_widget.add_button_clicked.connect((file_path) => {
                        add_button_clicked(file_path);
                    });

                    item_widget.play_button_clicked.connect((file_path) => {
                        play_button_clicked(file_path);
                    });

                    item_widget.show_all();
                    item_widget.hide_buttons();
                }

                finder.add(item_widget);

                double fraction = (double) (i + 1) / (double) file_info_list.size;
                progress.fraction = fraction;

                Idle.add(change_dir.callback);
                yield;

                i++;

                if (counter_holder != count) {
                    return;
                }
            }

            change_cursor(Gdk.CursorType.LEFT_PTR);
            progress_revealer.reveal_child = false;
            dir_changed(dir_path);
        }

        private void set_default_icon_size(int icon_size) {
            zoom_level = get_size_level(icon_size);
        }

        private void change_cursor(Gdk.CursorType cursor_type) {
            finder_container.get_parent_window().set_cursor(
                new Gdk.Cursor.for_display(Gdk.Screen.get_default().get_display(), cursor_type));
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
