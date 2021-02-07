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

 namespace Tatam {
     public class Window : Gtk.Window {
        private Tatam.Options options;
        private Tatam.GstPlayer? gst_player;
        private string config_dir;
        private Gtk.Entry location_entry;
        private Gtk.Button menu_button;
        private Gtk.Button parent_button;
        private Gtk.Button header_bookmark_button;
        private Gtk.Button header_reload_button;
        private Gtk.ToggleButton find_button;
        private Gtk.ToggleButton playlist_button;
        private Gtk.Popover sidebar_popover;
        private Tatam.Sidebar sidebar;
        private Tatam.Controller controller;
        private Tatam.PlaylistBox playlist_view;
        private Tatam.ArtworkView artwork_view;
        private Gtk.Revealer finder_revealer;
        private Gtk.Revealer playlist_revealer;
        private Tatam.Finder finder;
        private Gtk.Dialog save_playlist_dialog;
        private Gtk.Box box_1;

        private bool playing;
        private Tatam.FileInfoAdapter? file_info_reader;
        private Tatam.FileInfo? current_music;

        private string location {
            get {
                return location_entry.text;
            }
            set {
                location_entry.text = value;
                location_entry.activate();
            }
        }

        public Window(Tatam.Options options) {
            this.options = options;
            config_dir = options.get(Tatam.OptionKey.CONFIG_DIR);
            playing = false;
            setup_gst_player();
            setup_file_info_adapter();
            setup_widgets();
            setup_css(options.get(Tatam.OptionKey.CSS_PATH));
            init_bookmarks_of_sidebar();
            init_playlists_of_sidebar();
        }

        private void setup_widgets() {
            var header_bar = new Gtk.HeaderBar();
            {
                var left_button_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
                {
                    find_button = new Gtk.ToggleButton();
                    {
                        find_button.image = new Gtk.Image.from_icon_name(Tatam.IconName.Symbolic.FOLDER_OPEN,
                                Gtk.IconSize.SMALL_TOOLBAR);
                        find_button.clicked.connect(() => {
                            if (find_button.active) {
                                playlist_button.active = false;
                                show_finder();
                            } else {
                                playlist_button.active = true;
                                show_playlist();
                            }
                        });
                        find_button.active = true;
                    }

                    playlist_button = new Gtk.ToggleButton();
                    {
                        playlist_button.image = new Gtk.Image.from_icon_name(Tatam.IconName.Symbolic.EMBLEM_MUSIC,
                                Gtk.IconSize.SMALL_TOOLBAR);
                        playlist_button.clicked.connect(() => {
                            if (playlist_button.active) {
                                find_button.active = false;
                                show_playlist();
                            } else {
                                find_button.active = true;
                                show_finder();
                            }
                        });
                    }

                    left_button_box.layout_style = Gtk.ButtonBoxStyle.EXPAND;
                    left_button_box.add(find_button);
                    left_button_box.add(playlist_button);
                }

                var location_box = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
                {
                    parent_button = new Gtk.Button.from_icon_name(Tatam.IconName.Symbolic.GO_UP);
                    {
                        parent_button.clicked.connect(() => {
                            File dir = File.new_for_path(location).get_parent();
                            location = dir.get_path();
                        });
                    }

                    header_bookmark_button = new Gtk.Button.from_icon_name(Tatam.IconName.Symbolic.BOOKMARK_NEW);
                    {
                        header_bookmark_button.clicked.connect(() => {
                            if (!sidebar.has_bookmark(location)) {
                                sidebar.add_bookmark(location);
                            } else if (Tatam.Dialogs.confirm(_("Do you really remove this bookmark?"), this)) {
                                sidebar.remove_bookmark(location);
                            }
                        });
                    }

                    location_entry = new Gtk.Entry();
                    {
                        location_entry.hexpand = true;
                        location_entry.activate.connect(() => {
                            finder.change_dir.begin(location);
                        });
                    }

                    header_reload_button = new Gtk.Button.from_icon_name(Tatam.IconName.Symbolic.VIEW_REFRESH);
                    {
                        header_reload_button.clicked.connect(() => {
                            finder.change_dir.begin(location);
                        });
                    }

                    location_box.pack_start(header_bookmark_button, false, true);
                    location_box.pack_start(parent_button, false, true);
                    location_box.pack_start(location_entry, true, true);
                    location_box.pack_start(header_reload_button, false, true);
                    location_box.layout_style = Gtk.ButtonBoxStyle.EXPAND;
                    location_box.homogeneous = false;
                    location_box.margin_start = 30;
                    location_box.margin_end = 30;
                }

                menu_button = new Gtk.Button.from_icon_name(Tatam.IconName.Symbolic.OPEN_MENU);
                {
                    sidebar_popover = new Gtk.Popover(menu_button);
                    {
                        sidebar = new Tatam.Sidebar();
                        {
                            sidebar.bookmark_directory_selected.connect((dir_path) => {
                                sidebar_popover.visible = false;
                                location = dir_path;
                                if (!finder_revealer.child_revealed) {
                                    show_finder();
                                    find_button.active = true;
                                    playlist_button.active = false;
                                }
                            });

                            sidebar.bookmark_del_button_clicked.connect((dir_path) => {
                                sidebar_popover.visible = false;
                                return Tatam.Dialogs.confirm(_("Do you really remove this bookmark?"), this);
                            });

                            sidebar.playlist_selected.connect((playlist_name, playlist_path) => {
                                sidebar_popover.visible = false;
                                try {
                                    playlist_view.load_list_from_file(playlist_path);
                                    controller.activate_buttons(!playlist_view.has_previous(),
                                                                !playlist_view.has_next());
                                    if (!playlist_revealer.child_revealed) {
                                        show_playlist();
                                        find_button.active = false;
                                        playlist_button.active = true;
                                    }
                                } catch (FileError e) {
                                    stderr.printf(@"FileError: $(e.message)\n");
                                } catch (GLib.Error e) {
                                    stderr.printf(@"GError: $(e.message)\n");
                                }
                            });

                            sidebar.playlist_del_button_clicked.connect((playlist_path) => {
                                sidebar_popover.visible = false;
                                bool answer = Tatam.Dialogs.confirm(_("Do you really remove this playlist?"), this);
                                if (answer) {
                                    File playlist_file = File.new_for_path(playlist_path);
                                    try {
                                        playlist_file.delete();
                                    } catch (GLib.Error e) {
                                        Dialogs.alert(_("Failed to delete a file (%s)").printf(playlist_path), this);
                                    }
                                }
                                return answer;
                            });

                            sidebar.file_chooser_called.connect(() => {
                                sidebar_popover.visible = false;
                                string? dir_path = Tatam.Dialogs.choose_directory(this);
                                if (dir_path != null) {
                                    location = dir_path;
                                }
                                if (playlist_revealer.child_revealed) {
                                    show_finder();
                                    find_button.active = true;
                                    playlist_button.active = false;
                                }
                            });

                            sidebar.bookmark_added.connect((file_path) => {

                            });

                            sidebar.show_all();
                        }

                        sidebar_popover.add(sidebar);
                        sidebar_popover.modal = true;
                    }

                    menu_button.relief = Gtk.ReliefStyle.NONE;
                    menu_button.clicked.connect(() => {
                        sidebar_popover.visible = !sidebar_popover.visible;
                    });
                }

                header_bar.pack_start(left_button_box);
                header_bar.set_custom_title(location_box);
                header_bar.pack_end(menu_button);
                header_bar.show_close_button = true;
            }

            box_1 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            {
                finder_revealer = new Gtk.Revealer();
                {
                    finder = Tatam.Finder.create_default_instance();
                    {
                        finder.dir_selected.connect((path) => {
                            location_entry.text = path;
                        });

                        finder.bookmark_button_clicked.connect((file_path) => {
                            if (!sidebar.has_bookmark(file_path)) {
                                sidebar.add_bookmark(file_path);
                            } else if (Tatam.Dialogs.confirm(_("Do you really remove this bookmark?"), this)) {
                                sidebar.remove_bookmark(file_path);
                            }
                        });

                        finder.play_button_clicked.connect((path) => {
                            setup_playlist.begin(path, false, (res, obj) => {
                                playlist_view.set_index(0);
                                gst_player.play(playlist_view.get_file_info().path);
                                show_playlist();
                                find_button.active = false;
                                playlist_button.active = true;
                            });
                            show_playlist();
                        });

                        finder.add_button_clicked.connect((path) => {
                            show_playlist();
                            find_button.active = false;
                            playlist_button.active = true;
                            setup_playlist.begin(path, true);
                        });
                    }

                    finder_revealer.child = finder;
                    finder_revealer.reveal_child = true;
                    finder_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
                }

                controller = new Tatam.Controller();
                {
                    controller.artwork_size = uint.parse(options.get(Tatam.OptionKey.CONTROLLER_IMAGE_SIZE_MIN));
                    controller.artwork_clicked.connect(() => {
                        if (playlist_revealer.child_revealed) {
                            controller.hide_artwork();
                            artwork_view.visible = true;
                            Timeout.add(300, () => {
                                artwork_view.fit_image();
                                return false;
                            });
                        }
                    });

                    controller.play_button_clicked.connect(() => {
                        debug("controller.play_button_clicked");
                        if (!playing) {
                            gst_player.play(playlist_view.get_file_info().path);
                            playing = true;
                        } else {
                            gst_player.unpause();
                        }
                    });

                    controller.pause_button_clicked.connect(() => {
                        debug("controller.pause_button_clicked");
                        gst_player.pause();
                    });

                    controller.next_button_clicked.connect(() => {
                        debug("controller.next_button_clicked");
                        if (playlist_view.has_next()) {
                            playlist_view.next();
                            set_controller_artwork();
                            gst_player.play(playlist_view.get_file_info().path);
                        }
                    });

                    controller.prev_button_clicked.connect(() => {
                        debug("controller.prev_button_clicked");
                        if (controller.music_current_time > 1000) {
                            controller.music_current_time = 0;
                            gst_player.quit();
                            gst_player.play(playlist_view.get_file_info().path);
                        } else if (playlist_view.has_previous()) {
                            playlist_view.previous();
                            set_controller_artwork();
                            gst_player.play(playlist_view.get_file_info().path);
                        }
                    });

                    controller.time_position_changed.connect((new_value) => {
                        debug("controller.time_position_changed");
                        gst_player.set_position(new Tatam.SmallTime.from_milliseconds((uint) new_value));
                    });

                    controller.volume_changed.connect((value) => {
                        debug("controller.volume_changed");
                        gst_player.volume = value;
                    });

                    controller.shuffle_button_toggled.connect((shuffle_on) => {
                        debug("shuffle was set to %s", shuffle_on ? "ON" : "OFF");
                        playlist_view.set_shuffling(shuffle_on);
                    });

                    controller.repeat_button_toggled.connect((repeat_on) => {
                        debug("repeating was set to %s", repeat_on ? "ON" : "OFF");
                        playlist_view.set_repeating(repeat_on);
                    });
                }

                playlist_revealer = new Gtk.Revealer();
                {
                    Gtk.Overlay playlist_overlay = new Gtk.Overlay();
                    {
                        Gtk.Box box_3 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
                        {
                            playlist_view = new Tatam.PlaylistBox();
                            {
                                playlist_view.image_size = 48;
                                playlist_view.item_activated.connect((index, file_info) => {
                                    if (current_music != null && current_music.path == file_info.path) {
                                        if (gst_player.status == Gst.State.PLAYING) {
                                            gst_player.pause();
                                            controller.pause();
                                        } else if (gst_player.status == Gst.State.PAUSED) {
                                            gst_player.unpause();
                                            controller.unpause();
                                        }
                                    } else {
                                        gst_player.quit();
                                        debug("playlist item activated at %u, %s", index, file_info.path);
                                        gst_player.play(playlist_view.get_file_info().path);
                                    }
                                });
                            }

                            Gtk.Box box_4 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
                            {
                                Gtk.ButtonBox box_5 = new Gtk.ButtonBox(Gtk.Orientation.HORIZONTAL);
                                {
                                    var move_up_button = new Gtk.Button.from_icon_name(IconName.Symbolic.GO_UP, Gtk.IconSize.SMALL_TOOLBAR);
                                    {
                                        move_up_button.tooltip_text = _("Move up selected items");
                                        move_up_button.clicked.connect(() => {
                                            playlist_view.move_up_items();
                                        });
                                    }

                                    var move_down_button = new Gtk.Button.from_icon_name(
                                            IconName.Symbolic.GO_DOWN, Gtk.IconSize.SMALL_TOOLBAR);
                                    {
                                        move_down_button.tooltip_text = _("Move down selected items");
                                        move_down_button.clicked.connect(() => {
                                            playlist_view.move_down_items();
                                        });
                                    }

                                    var list_remove_button = new Gtk.Button.from_icon_name(
                                            IconName.Symbolic.LIST_REMOVE, Gtk.IconSize.SMALL_TOOLBAR);
                                    {
                                        list_remove_button.tooltip_text = _("Remove selected items");
                                        list_remove_button.clicked.connect(() => {
                                            playlist_view.remove_items();
                                        });
                                    }

                                    var list_unselect_button = new Gtk.Button.from_icon_name(
                                            IconName.Symbolic.OBJECT_SELECT, Gtk.IconSize.SMALL_TOOLBAR);
                                    {
                                        list_unselect_button.tooltip_text = _("Unselect all items");
                                        list_unselect_button.clicked.connect(() => {
                                            playlist_view.unselect_all();
                                        });
                                    }

                                    box_5.layout_style = Gtk.ButtonBoxStyle.EXPAND;
                                    box_5.add(move_up_button);
                                    box_5.add(move_down_button);
                                    box_5.add(list_remove_button);
                                    box_5.add(list_unselect_button);
                                }

                                Gtk.Button save_button = new Gtk.Button.from_icon_name(Tatam.IconName.Symbolic.DOCUMENT_SAVE);
                                {
                                    save_button.tooltip_text = _("Save this playlist");
                                    save_button.clicked.connect(() => {
                                        Gee.List<string> file_path_list = new Gee.ArrayList<string>();
                                        for (int i = 0; i < playlist_view.get_list_size(); i++) {
                                            file_path_list.add(playlist_view.get_file_info_at_index(i).path);
                                        }
                                        string playlist_name = playlist_view.playlist_name;
                                        if (playlist_view.playlist_name == null) {
                                            save_playlist(file_path_list);
                                        } else if (sidebar.has_playlist(playlist_name)) {
                                            if (Tatam.Dialogs.confirm(_("A playlist %s exists. Do you overwrite it?").printf(playlist_name), this)) {
                                                overwrite_playlist(playlist_name, file_path_list);
                                            } else {
                                                save_playlist(file_path_list);
                                            }
                                        }
                                    });
                                }

                                box_4.pack_end(save_button, false, false);
                                box_4.pack_end(box_5, false, false);
                            }

                            box_3.margin = 2;
                            box_3.pack_start(playlist_view, true, true);
                            box_3.pack_start(box_4, false, false);
                        }

                        artwork_view = new Tatam.ArtworkView();
                        {
                            artwork_view.close_button_clicked.connect(() => {
                                controller.show_artwork();
                                artwork_view.visible = false;
                            });
                        }

                        playlist_overlay.add(box_3);
                        playlist_overlay.add_overlay(artwork_view);
                    }

                    playlist_revealer.child = playlist_overlay;
                    playlist_revealer.reveal_child = false;
                    playlist_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
                }

                box_1.pack_start(finder_revealer, true, true);
                box_1.pack_start(controller, false, false);
                box_1.pack_start(playlist_revealer, false, false);
            }

            set_titlebar(header_bar);
            add(box_1);
            set_title(Tatam.PROGRAM_NAME);
            set_default_size(700, 500);
            configure_event.connect((cr) => {
                if (artwork_view.visible && controller.has_artwork()) {
                    artwork_view.fit_image();
                }
                return false;
            });
            destroy.connect(this.quit);
        }

        public override void show_all() {
            base.show_all();
            artwork_view.visible = false;
            init_playlist.begin();
            finder.change_dir.begin(options.get(Tatam.OptionKey.LAST_VISITED_DIR));
        }

        public void quit() {
            gst_player.destroy();
            save_config_file();
        }

        public void save_config_file() {
            options.set(Tatam.OptionKey.LAST_VISITED_DIR, location);
            options.set(Tatam.OptionKey.LAST_PLAYLIST_NAME, playlist_view.playlist_name);
            options.remove_key(Tatam.OptionKey.BOOKMARK_DIR);
            foreach (string bookmark_dir in sidebar.get_bookmarks()) {
                options.set(Tatam.OptionKey.BOOKMARK_DIR, bookmark_dir);
            }
            options.remove_key(Tatam.OptionKey.PLAYLIST_ITEM);
            for (uint i = 0; i < playlist_view.get_list_size(); i++) {
                string playlist_item_path = playlist_view.get_file_info_at_index(i).path;
                options.set(Tatam.OptionKey.PLAYLIST_ITEM, playlist_item_path);
            }
            Tatam.StringJoiner config_file_contents = new Tatam.StringJoiner("\n", null, "\n");
            foreach (Tatam.OptionKey key in options.keys()) {
                switch (key) {
                case Tatam.OptionKey.CSS_PATH:
                case Tatam.OptionKey.CONFIG_DIR:
                    break;
                case Tatam.OptionKey.BOOKMARK_DIR:
                case Tatam.OptionKey.PLAYLIST_ITEM:
                    foreach (string value in options.get_all(key)) {
                        config_file_contents.add(@"$(key.get_long_name())=$(value)");
                    }
                    break;
                default:
                    config_file_contents.add(@"$(key.get_long_name())=$(options.get(key))");
                    break;
                }
            }
            try {
                string config_dir = options.get(Tatam.OptionKey.CONFIG_DIR);
                string config_file_path = @"$(config_dir)/$(Tatam.PROGRAM_NAME).conf";
                debug(@"Save config data to $(config_file_path)");
                string config_data = config_file_contents.to_string();
                debug(@"Saved config data contents: $(config_data)");
                FileUtils.set_contents(config_file_path, config_data);
            } catch (FileError e) {
                stderr.printf(@"FileError: $(e.message)\n");
            }
        }

        private void setup_gst_player() {
            gst_player = new Tatam.GstPlayer();
            gst_player.volume = 0.5;
            gst_player.started.connect(() => {
                debug("gst_player.started was called");
                set_controller_artwork();
                controller.play_pause_button_state = Tatam.ControllerState.PLAY;
                current_music = playlist_view.get_file_info();

                if (current_music.artwork != null) {
                    artwork_view.artwork = current_music.artwork;
                    if (!artwork_view.visible) {
                        controller.show_artwork();
                    } else {
                        Idle.add(() => {
                            artwork_view.fit_image();
                            return false;
                        });
                    }
                } else {
                    controller.hide_artwork();
                    artwork_view.set_image_from_icon_name(Tatam.IconName.AUDIO_FILE);
                }
            });

            gst_player.error_occured.connect((error) => {
                debug("gst_player.error_occured was called");
                stderr.printf(@"Error: $(error.message)\n");
            });

            gst_player.finished.connect(() => {
                debug("gst_player.finished was called");
                if (playlist_view.has_next()) {
                    debug("playlist has next track");
                    playlist_view.next();
                    debug("playlist moved to next track");
                    Tatam.FileInfo? next_file_info = playlist_view.get_file_info();
                    if (next_file_info != null) {
                        string next_path = next_file_info.path;
                        gst_player.play(next_path);
                    }
                } else {
                    debug("playing all files is completed!");
                    playing = false;
                    current_music = null;
                }
            });

            gst_player.unpaused.connect(() => {
                debug("gst_player.unpaused was called");
                playlist_view.toggle_status();
            });

            gst_player.paused.connect(() => {
                debug("gst_player.paused was called");
                playlist_view.toggle_status();
            });
        }

        private void setup_file_info_adapter() {
            file_info_reader = new Tatam.FileInfoAdapter();
        }

        private void show_finder() {
            parent_button.sensitive = true;
            header_bookmark_button.sensitive = true;
            header_reload_button.sensitive = true;
            location_entry.sensitive = true;
            parent_button.sensitive = true;
            finder_revealer.reveal_child = true;
            box_1.set_child_packing(finder_revealer, true, true, 0, Gtk.PackType.START);
            playlist_revealer.reveal_child = false;
            box_1.set_child_packing(playlist_revealer, false, false, 0, Gtk.PackType.START);
            controller.artwork_size = uint.parse(options.get(Tatam.OptionKey.CONTROLLER_IMAGE_SIZE_MIN));
        }

        private void show_playlist() {
            parent_button.sensitive = false;
            header_bookmark_button.sensitive = false;
            header_reload_button.sensitive = false;
            location_entry.sensitive = false;
            parent_button.sensitive = false;
            finder_revealer.reveal_child = false;
            box_1.set_child_packing(finder_revealer, false, false, 0, Gtk.PackType.START);
            playlist_revealer.reveal_child = true;
            box_1.set_child_packing(playlist_revealer, true, true, 0, Gtk.PackType.START);
            controller.artwork_size = uint.parse(options.get(Tatam.OptionKey.CONTROLLER_IMAGE_SIZE_MAX));
        }

        private void set_controller_artwork() {
            Tatam.FileInfo? info = playlist_view.get_file_info();
            if (info == null) {
                return;
            }
            if (info.title != null) {
                controller.music_title = info.title;
            } else {
                controller.music_title = info.name;
            }
            controller.music_total_time = info.time_length.milliseconds;
            controller.activate_buttons(!playlist_view.has_previous(), !playlist_view.has_next());
            if (info.artwork != null) {
                controller.set_artwork(info.artwork);
            }
            debug("set_controller_artwork is completed");
        }

        private async void setup_playlist(string path, bool append_mode) {
            if (!append_mode) {
                playlist_view.remove_all();
            }
            debug(@"setup playlist of $(path)\n");
            var setup_playlist_thread = new Thread<Gee.List<Tatam.FileInfo?> >(null, () => {
                try {
                    var playlist_internal = Tatam.Files.find_file_infos_recursively(path);
                    debug("playlist was loaded\n");
                    return playlist_internal;
                } catch (FileError e) {
                    stderr.printf(@"FileError: $(e.message)\n");
                    return new Gee.ArrayList<Tatam.FileInfo?>();
                } finally {
                    Idle.add(setup_playlist.callback);
                }
            });
            yield;
            var playlist = setup_playlist_thread.join();
            if (playlist.size > 0) {
                foreach (var file_info in playlist) {
                    playlist_view.add_item(file_info);
                }
                controller.activate_buttons(!playlist_view.has_previous(), !playlist_view.has_next());
            }
        }

        private void save_playlist(Gee.List<string> file_path_list) {
            if (save_playlist_dialog == null) {
                Gtk.Entry playlist_name_entry;
                Gee.List<string> copy_of_list = file_path_list;
                save_playlist_dialog = new Gtk.Dialog.with_buttons(Tatam.PROGRAM_NAME + ": save playlist", this,
                        Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                        _("_OK"), Gtk.ResponseType.ACCEPT,
                        _("_Cancel"), Gtk.ResponseType.CANCEL);
                {
                    var save_playlist_dialog_hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
                    {
                        var label = new Gtk.Label(_("Enter new playlist name:"));
                        playlist_name_entry = new Gtk.Entry();
                        save_playlist_dialog_hbox.pack_start(label);
                        save_playlist_dialog_hbox.pack_start(playlist_name_entry);
                    }

                    save_playlist_dialog.get_content_area().add(save_playlist_dialog_hbox);
                    save_playlist_dialog.response.connect((response_id) => {
                        if (response_id == Gtk.ResponseType.ACCEPT) {
                            string playlist_name = playlist_name_entry.text;
                            string playlist_path = get_playlist_path_from_name(playlist_name);
                            sidebar.add_playlist(playlist_name, playlist_path);
                            debug("playlist name was saved: %s", playlist_name);
                            overwrite_playlist(playlist_name, copy_of_list);
                            playlist_view.playlist_name = playlist_name;
                        }
                        playlist_name_entry.text = "";
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

        private void overwrite_playlist(string playlist_name, Gee.List<string> file_path_list) {
            string playlist_file_path = get_playlist_path_from_name(playlist_name);
            Tatam.StringJoiner playlist_file_contents = new Tatam.StringJoiner("\n", null, "\n");
            playlist_file_contents.add_all(file_path_list);
            try {
                File file = File.new_for_path(playlist_file_path);
                File parent = file.get_parent();
                if (!parent.query_exists()) {
                    DirUtils.create_with_parents(parent.get_path(), 0755);
                }
                FileUtils.set_contents(playlist_file_path, playlist_file_contents.to_string());
                debug("playlist file has been saved at %s", playlist_file_path);
            } catch (FileError e) {
                stderr.printf(_("Error: can not write to config file.\n"));
                Process.exit(1);
            }
        }

        private void init_bookmarks_of_sidebar() {
            Gee.List<string> bookmarks = options.get_all(Tatam.OptionKey.BOOKMARK_DIR);
            foreach (string bookmark_path in bookmarks) {
                debug(@"bookmark_path: $(bookmark_path)");
                sidebar.add_bookmark(bookmark_path);
            }
        }

        private void init_playlists_of_sidebar() {
            try {
                Tatam.DirectoryReader dreader = new Tatam.DirectoryReader(config_dir);
                dreader.file_found.connect((file) => {
                    if (file.get_basename().has_suffix(".m3u")) {
                        string playlist_name = Tatam.FilePathUtils.remove_extension(file.get_basename());
                        string playlist_path = file.get_path();
                        sidebar.add_playlist(playlist_name, playlist_path);
                    }
                    return true;
                });
                dreader.run();
            } catch (FileError e) {
                stderr.printf(@"FileError: $(e.message)\n");
            } catch (Tatam.Error e) {
                stderr.printf(@"FileError: $(e.message)\n");
            }
        }

        private async void init_playlist() {
            menu_button.sensitive = false;
            new Thread<bool>(null, () => {
                try {
                    Gee.List<string> last_playlist = options.get_all(Tatam.OptionKey.PLAYLIST_ITEM);
                    if (last_playlist.size == 0) {
                        return true;
                    }
                    foreach (string item in last_playlist) {
                        Tatam.FileInfo info = file_info_reader.read_metadata_from_path(item);
                        playlist_view.add_item(info);
                    }
                    return true;
                } finally {
                    Idle.add(init_playlist.callback);
                }
            });
            yield;
            controller.activate_buttons(!playlist_view.has_previous(), !playlist_view.has_next());
            menu_button.sensitive = true;
        }

        private string get_playlist_path_from_name(string playlist_name) {
            return config_dir + "/" + playlist_name + ".m3u";
        }

        protected void setup_css(string css_path) {
            if (GLib.FileUtils.test(css_path, FileTest.EXISTS)) {
                debug("css exists at %s", css_path);
                Gdk.Screen win_screen = get_screen();
                Gtk.CssProvider css_provider = new Gtk.CssProvider();
                try {
                    css_provider.load_from_path(css_path);
                } catch (GLib.Error e) {
                    debug("ERROR: css_path: %s", css_path);
                    stderr.printf(_("ERROR: failed to create a window\n"));
                    return;
                }
                Gtk.StyleContext.add_provider_for_screen(win_screen,
                                                         css_provider,
                                                         Gtk.STYLE_PROVIDER_PRIORITY_USER);
            } else {
                debug("css does not exists!");
            }
        }
    }
}
