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
    public class Window : Gtk.Window {
        private const string[] icon_dirs = {
            "/usr/share/icons/hicolor/48x48/apps/",
            "/usr/local/share/icons/hicolor/48x48/apps/",
            "~/.icons"
        };

        private Tatam.HeaderBar header_bar;
        private Tatam.Stack stack;
        private Tatam.Sidebar sidebar;
        private Tatam.FinderToolbar finder_toolbar;
        private Tatam.Finder finder;
        private Tatam.PlaylistBox playlist_view;
        private Tatam.Controller controller;

        private Button music_view_close_button;
        private TreeViewColumn bookmark_title_col;
        private Gdk.Screen default_screen;

        private Overlay music_view_overlay;
        private Image music_view_artwork;
        private ScrolledWindow music_view_container;
        private int saved_width;
        private int saved_height;

        private Tatam.GstPlayer music;
        
        private Dialog? help_dialog = null;
        private Dialog? save_playlist_dialog = null;
        
        private uint max_width;
        private uint max_height;
        private uint reserved_default_height;
        private uint reserved_default_width;
        
        private Tatam.Options options;
        private Tatam.FileInfoAdapter file_info_reader;
        
        private Gdk.Pixbuf? file_pixbuf;
        private Gdk.Pixbuf? cd_pixbuf;
        private Gdk.Pixbuf? folder_pixbuf;

        public Window(Tatam.Options options) {
            this.options = options;

            default_screen = Gdk.Screen.get_default();

            max_width = default_screen.get_width();

            max_height = default_screen.get_height();
            debug("get screen: " + (default_screen != null ? "ok." : "failed"));
            debug("Max width of the display: " + max_width.to_string());
            debug("Max height of the display: " + max_height.to_string());

            reserved_default_height = (int) (max_height * 0.7);
            reserved_default_width = int.min((int) (max_width * 0.5), (int) (reserved_default_height * 1.3));

            artwork_max_size = int.min((int) max_width, (int) max_height);

            IconTheme icon_theme = Gtk.IconTheme.get_default();

            file_info_reader = new Tatam.FileInfoAdapter();

            try {
                file_pixbuf = icon_theme.load_icon(IconName.AUDIO_FILE, 64, 0);
                cd_pixbuf = icon_theme.load_icon(IconName.MEDIA_OPTICAL, 64, 0);
                folder_pixbuf = icon_theme.load_icon(IconName.FOLDER_MUSIC, 64, 0);
                if (folder_pixbuf == null) {
                    folder_pixbuf = icon_theme.load_icon(IconName.FOLDER, 64, 0);
                }
            } catch (Error e) {
                stderr.printf(Text.ERROR_LOAD_ICON);
                Process.exit(1);
            }

            construct_widgets();
        }

        private void construct_widgets() {
            header_bar = new Tatam.HeaderBar();
            {
                header_bar.switch_button_clicked.connect((switch_button_state) => {
                        if (switch_button_state == Tatam.HeaderBar.SwitchButtonState.PLAYLIST) {
                        } else {
                        }
                    });

                header_bar.add_button_clicked.connect(() => {
                    });

                header_bar.fold_button_clicked.connect((fold_button_state) => {
                        if (fold_button_state == Tatam.HeaderBar.FoldButtonState.FOLDED) {
                        } else {
                        }
                    });

                header_bar.about_button_clicked.connect(() => {
                        show_about_dialog();
                    });
            }
            
            var top_box = new Box(Orientation.VERTICAL, 0);
            {
                var main_overlay = new Overlay();
                {
                    stack = new Tatam.Stack();
                    {
                        var finder_paned = new Paned(Orientation.HORIZONTAL);
                        {
                            sidebar = new Tatam.Sidebar();
                            {
                                sidebar.bookmark_directory_selected.connect((dir_path) => {
                                    });

                                sidebar.bookmark_del_button_clicked.connect(() => {
                                        return true;
                                    });

                                sidebar.playlist_selected.connect((playlist_name, playlist_path) => {
                                    });

                                sidebar.playlist_del_button_clicked.connect((playlist_path) => {
                                        return true;
                                    });
            
                                sidebar.file_chooser_called.connect(() => {
                                    });

                                sidebar.bookmark_added.connect((file_path) => {
                                    });
                            }
                            
                            var finder_box = new Box(Orientation.VERTICAL, 4);
                            {
                                finder_toolbar = new FinderToolbar();
                                {
                                    finder_toolbar.parent_button_clicked.connect(() => {
                                        });

                                    finder_toolbar.zoomin_button_clicked.connect(() => {
                                            finder.zoom_in();
                                        });

                                    finder_toolbar.zoomout_button_clicked.connect(() => {
                                            finder.zoom_out();
                                        });

                                    finder_toolbar.location_entered.connect((location) => {
                                            if (GLib.FileUtils.test(location, FileTest.IS_DIR)) {
                                                finder.change_dir.begin(location);
                                            }
                                        });

                                    finder_toolbar.refresh_button_clicked.connect(() => {
                                            finder.change_dir.begin(current_dir);
                                        });

                                    finder_toolbar.add_button_clicked.connect(() => {
                                            playlist_save_action();
                                        });
                                }
                                
                                var finder_overlay = new Overlay();
                                {
                                    finder = new Tatam.Finder
                                    .Builder()
                                    .file_pixbuf(file_pixbuf)
                                    .disc_pixbuf(cd_pixbuf)
                                    .folder_pixbuf(folder_pixbuf)
                                    .build();
                                    {
                                        finder.set_default_icon_size(options.icon_size);

                                        finder.dir_changed.connect((path) => {
                                            });
                    
                                        finder.bookmark_button_clicked.connect((file_path) => {
                                            });

                                        finder.play_button_clicked.connect((file_path) => {
                                            });

                                        finder.add_button_clicked.connect((file_path) => {
                                            });

                                        finder.icon_image_resized.connect((icon_size) => {
                                            });

                                        finder.file_button_clicked.connect((file_path) => {
                                            });

                                        finder.use_popover = false;
                                    }
                                    
                                    finder_overlay.add(finder);
                                }

                                finder_box.pack_start(finder_toolbar, false, false);
                                finder_box.pack_start(finder_overlay, true, true);
                            }
        
                            finder_paned.pack1(sidebar, false, true);
                            finder_paned.pack2(finder_box, true, true);
                        }
                        
                        var playlist_vbox = new Box(Orientation.HORIZONTAL, 0);
                        {
                            var playlist_view_container = new ScrolledWindow(null, null);
                            {
                                playlist_view = new PlaylistBox();
                                {
                                    playlist_view.image_size = options.playlist_image_size;
                                    playlist_view.row_activated.connect((index, file_info) => {
                                        });
                
                                    playlist_view.changed.connect((file_path_list) => {
                                        });
                                }
                                playlist_view_container.add(playlist_view);
                            }

                            playlist_vbox.pack_start(playlist_view_container, true, true);
                        }
                        
                        stack.add_named(finder_paned, "finder");
                        stack.add_named(playlist_vbox, "playlist");
                        stack.finder_is_selected.connect(() => {
                                header_bar.show_add_button();
                            });
                        stack.playlist_is_selected.connect(() => {
                                header_bar.show_add_button();
                            });
                    }
                
                    music_view_overlay = new Overlay();
                    {
                        music_view_close_button = new Button.from_icon_name(
                            IconName.Symbolic.WINDOW_CLOSE, IconSize.BUTTON);
                        {
                            music_view_close_button.halign = Align.END;
                            music_view_close_button.valign = Align.START;
                            music_view_close_button.margin = 10;
                            music_view_close_button.clicked.connect(() => {
                                    controller.show_artwork();
                                    music_view_overlay.visible = false;
                                    header_bar.enable_switch_button();
//                                    finder_add_button.sensitive = true;
                                });
                        }

                        music_view_container = new ScrolledWindow(null, null);
                        {
                            music_view_container.get_style_context().add_class(
                                StyleClass.ARTWORK_BACKGROUND);
                        }

                        music_view_artwork = new Image();
                        {
                            music_view_artwork.margin = 0;
                            music_view_container.add(music_view_artwork);
                        }

                        music_view_overlay.add(music_view_container);
                        music_view_overlay.add_overlay(music_view_close_button);
                        music_view_overlay.set_overlay_pass_through(music_view_close_button, true);
                    }
                    
                    main_overlay.add(stack);
                    main_overlay.add_overlay(music_view_overlay);
                }

                controller = new Tatam.Controller();
                {
                    controller.play_button_clicked.connect(() => {
                        });

                    controller.pause_button_clicked.connect(() => {
                        });

                    controller.next_button_clicked.connect(() => {
                        });

                    controller.prev_button_clicked.connect(() => {
                        });

                    controller.time_position_changed.connect((new_value) => {
                        });

                    controller.volume_changed.connect((value) => {
                        });

                    controller.artwork_clicked.connect(() => {
                        });

                    controller.shuffle_button_toggled.connect((shuffle_on) => {
                        });                

                    controller.repeat_button_toggled.connect((repeat_on) => {
                        });
                }
                
                top_box.pack_start(main_overlay, true, true);
                top_box.pack_start(controller, false, false);
            }

            this.add(top_box);
            this.set_titlebar(header_bar);
            this.border_width = 0;
            this.window_position = WindowPosition.CENTER;
            this.resizable = true;
            this.set_default_size((int)reserved_default_width, (int)reserved_default_height);
            this.destroy.connect(application_quit);
            this.configure_event.connect((cr) => {
                    if (music_view_overlay.visible && current_playing_artwork != null) {
                        int size = int.min(music_view_container.get_allocated_width(),
                                           music_view_container.get_allocated_height());
                        music_view_artwork.pixbuf = PixbufUtils.scale(current_playing_artwork, size);
                    }
                    bookmark_title_col.max_width = this.get_allocated_width() / 4;
                    return false;
                });

            this.show_all();

            if (GLib.FileUtils.test(options.css_path, FileTest.EXISTS)) {
                Gdk.Screen win_screen = this.get_screen();
                CssProvider css_provider = new CssProvider();
                try {
                    css_provider.load_from_path(options.css_path);
                } catch (Error e) {
                    debug("ERROR: css_path: %s", options.css_path);
                    stderr.printf(Text.ERROR_CREATE_WINDOW);
                    return;
                }
                Gtk.StyleContext.add_provider_for_screen(win_screen,
                                                         css_provider,
                                                         Gtk.STYLE_PROVIDER_PRIORITY_USER);
            }

            controller.hide_artwork();
            controller.deactivate_buttons();
            music_view_overlay.visible = false;
            
        }

        private void setup_music() {
            music = new Tatam.GstPlayer();
            music.volume = 0.5;

            music.started.connect(() => {
                });

            music.error_occured.connect((error) => {
                });

            music.finished.connect(() => {
                });

            music.unpaused.connect(() => {
                });

            music.paused.connect(() => {
                });
        }
        
        private void set_controller_artwork() {
            Tatam.FileInfo? info = playlist_view.get_item().file_info;
            if (info == null) {
                return;
            }
            if (info.title != null) {
                controller.music_title = info.title;
            } else {
                controller.music_title = info.name;
            }
            controller.music_total_time = info.time_length.milliseconds;
            controller.activate_buttons(playlist_view.track_is_first(), playlist_view.track_is_last());
            if (info.artwork != null) {
                controller.set_artwork(info.artwork);
            }
        }

        private void playlist_save_action() {
        }

        private void application_quit() {
            if (music.playing) {
                music.quit();
            }

            Idle.add(() => {
                    if (!music.playing) {
                        Gtk.main_quit();
                        if (playlist_view.name != null) {
                            options.last_playlist_name = playlist_view.name;
                        }
                        return Source.REMOVE;
                    } else {
                        return Source.CONTINUE;
                    }
                });
        }

        private void show_about_dialog() {
            if (help_dialog == null) {
                help_dialog = new Dialog.with_buttons(PROGRAM_NAME + " info",
                                                      this,
                                                      DialogFlags.MODAL | DialogFlags.DESTROY_WITH_PARENT,
                                                      "_OK",
                                                      ResponseType.NONE);
                {
                    var help_dialog_vbox = new Box(Orientation.VERTICAL, 0);
                    {
                        var help_dialog_label_text = new Label("<span size=\"24000\"><b>" + PROGRAM_NAME + "</b></span>");
                        help_dialog_label_text.use_markup = true;
                        help_dialog_label_text.margin = 10;

//                        help_dialog_vbox.pack_start(new Image.from_pixbuf(get_application_icon_at_size(64, 64)));
                        help_dialog_vbox.pack_start(help_dialog_label_text, false, false);
                        help_dialog_vbox.pack_start(new Label(Text.DESCRIPTION), false, false);
                        help_dialog_vbox.pack_start(new Label(Text.COPYRIGHT), false, false);
                        help_dialog_vbox.margin = 20;
                    }
                    help_dialog.get_content_area().add(help_dialog_vbox);
                    help_dialog.response.connect(() => {
                            help_dialog.visible = false;
                        });
                    help_dialog.destroy.connect(() => {
                            help_dialog = null;
                        });
                    help_dialog.show_all();
                }
            }
            help_dialog.visible = true;
        }

        void save_playlist(Gee.List<string> file_path_list) {
            if (save_playlist_dialog == null) {
                Entry playlist_name_entry;

                Gee.List<string> copy_of_list = file_path_list;

                save_playlist_dialog = new Dialog.with_buttons(PROGRAM_NAME + ": save playlist",
                                                               this,
                                                               DialogFlags.MODAL | DialogFlags.DESTROY_WITH_PARENT,
                                                               Text.DIALOG_OK,
                                                               ResponseType.ACCEPT,
                                                               Text.DIALOG_CANCEL,
                                                               ResponseType.CANCEL);
                {
                    var save_playlist_dialog_hbox = new Box(Orientation.HORIZONTAL, 5);
                    {
                        var label = new Label(Text.PLAYLIST_SAVE_NAME);
                        playlist_name_entry = new Entry();
                        save_playlist_dialog_hbox.pack_start(label);
                        save_playlist_dialog_hbox.pack_start(playlist_name_entry);
                    }
            
                    save_playlist_dialog.get_content_area().add(save_playlist_dialog_hbox);

                    save_playlist_dialog.response.connect((response_id) => {
                            if (response_id == ResponseType.ACCEPT) {
                                string playlist_name = playlist_name_entry.text;
                                string playlist_path = get_playlist_path_from_name(playlist_name);
                                sidebar.add_playlist(playlist_name, playlist_path);
                                debug("playlist name was saved: %s", playlist_name);
                                overwrite_playlist_file(playlist_name, copy_of_list);
                                playlist_view.name = playlist_name;
                            }
                            playlist_name_entry.text = Text.EMPTY;
                            save_playlist_dialog.visible = false;
                        });

                    save_playlist_dialog.destroy.connect(() => {
                            save_playlist_dialog = null;
                        });

                    save_playlist_dialog.show_all();
                }
            } else {
                save_playlist_dialog.visible = true;
            }
        }

        private void overwrite_playlist_file(string playlist_name, Gee.List<string> file_path_list) {
            string playlist_file_path = get_playlist_path_from_name(playlist_name);
            string playlist_file_contents = "";
            foreach (string file_path in file_path_list) {
                debug("overwrite_playlist_file: path=%s", file_path);
                playlist_file_contents += file_path + "\n";
            }
            debug("Begin new saved playlist contents:%s", playlist_file_path);
            debug(playlist_file_contents);
            debug("End new saved playlist contents");
            try {
                GLib.FileUtils.set_contents(playlist_file_path, playlist_file_contents);
                debug("playlist file has been saved");
            } catch (Error e) {
                stderr.printf(Text.ERROR_WRITE_CONFIG);
                Process.exit(1);
            }
        }

        private string get_playlist_path_from_name(string name) {
            return Environment.get_home_dir() + "/." + PROGRAM_NAME + "/" + name + ".m3u";
        }
    }
}
