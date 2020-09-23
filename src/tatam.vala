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

public interface TatamApplicationInterface {
    public abstract void run();
    public abstract void quit();
    public abstract void save_config_file();
}

public class TatamApplication : AppBase, TatamApplicationInterface {
    private static string config_dir;
    
    private Tatam.Options options;
    private Tatam.GstPlayer? gst_player;
    private Gtk.Window window;
    private Gtk.Entry location_entry;
    private Gtk.Button parent_button;
    private Gtk.Button find_button;
    private Tatam.Sidebar sidebar;
    private Tatam.Controller controller;
    private Tatam.PlaylistBox playlist_view;
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

    public TatamApplication(ref unowned string[] args) {
        playing = false;
        setup_configs(ref args);
        setup_gst_player();
        setup_file_info_adapter();
        setup_window();
        setup_css(window, options.get(Tatam.OptionKey.CSS_PATH));
        init_playlists_of_sidebar();
    }
    
    public void run() {
        finder.change_dir.begin(options.get(Tatam.OptionKey.LAST_VISITED_DIR));
    }
    
    public void quit() {
        gst_player.destroy();
        save_config_file();
        Gtk.main_quit();
    }

    public void save_config_file() {
        options.set(Tatam.OptionKey.LAST_VISITED_DIR, location);
        options.set(Tatam.OptionKey.LAST_PLAYLIST_NAME, playlist_view.playlist_name);
        Tatam.StringJoiner config_file_contents = new Tatam.StringJoiner("\n", null, "\n");
        foreach (Tatam.OptionKey key in options.keys()) {
            if (key == Tatam.OptionKey.CSS_PATH || key == Tatam.OptionKey.CONFIG_DIR) {
                continue;
            }
            config_file_contents.add(@"$(key.get_long_name())=$(options.get(key))");
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

    private void setup_configs(ref unowned string[] args) {
        options = new Tatam.Options();
        try {
            options.parse_conf();
        } catch (Tatam.Error e) {
            stderr.printf(@"TatamError: $(e.message)\n");
        }
        try {
            options.parse_args(ref args);
        } catch (Tatam.Error e) {
            stderr.printf(@"TatamError: $(e.message)\n");
        }
        if (!FileUtils.test(options.get(Tatam.OptionKey.CONFIG_DIR), FileTest.IS_DIR)) {
            DirUtils.create_with_parents(options.get(Tatam.OptionKey.CONFIG_DIR), 0755);
        }
        if (!FileUtils.test(options.get(Tatam.OptionKey.CSS_PATH), FileTest.IS_REGULAR)) {
            try {
                FileUtils.set_contents(options.get(Tatam.OptionKey.CSS_PATH), Tatam.DEFAULT_CSS);
            } catch (GLib.FileError e) {
                stderr.printf(@"FileError: $(e.message)\n");
            }
        }
    }

    private void setup_gst_player() {
        gst_player = new Tatam.GstPlayer();
        gst_player.volume = 0.5;
        gst_player.started.connect(() => {
                debug("gst_player.started was called");
                set_controller_artwork();
                controller.play_pause_button_state = Tatam.PlayPauseButtonState.PLAY;
                current_music = playlist_view.get_file_info();
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
                    string next_path = playlist_view.get_file_info().path;
                    gst_player.play(next_path);
                } else {
                    debug("playing all files is completed!");
                    playing = false;
                    current_music = null;
                }
            });
        gst_player.unpaused.connect(() => {
                print("gst_player.unpaused was called\n");
            });
        gst_player.paused.connect(() => {
                print("gst_player.paused was called\n");
            });
    }

    private void setup_file_info_adapter() {
        file_info_reader = new Tatam.FileInfoAdapter();
    }

    private void setup_window() {
        window = new Gtk.Window();
        {
            box_1 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            {
                Gtk.Box box_2 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                {
                    parent_button = new Gtk.Button.from_icon_name("go-up");
                    {
                        parent_button.clicked.connect(() => {
                                File dir = File.new_for_path(location).get_parent();
                                location = dir.get_path();
                            });
                    }
                    
                    location_entry = new Gtk.Entry();
                    {
                        location_entry.activate.connect(() => {
                                finder.change_dir.begin(location);
                            });
                    }
                    
                    find_button = new Gtk.Button.from_icon_name("folder-open-symbolic");
                    {
                        find_button.clicked.connect(() => {
                                if (!finder_revealer.child_revealed) {
                                    print("Call direcotry chooser\n");
                                    show_finder();
                                    Gtk.Image? icon = find_button.image as Gtk.Image;
                                    if (icon != null) {
                                        icon.icon_name = Tatam.IconName.Symbolic.WINDOW_CLOSE;
                                    }
                                } else {
                                    show_playlist();
                                    Gtk.Image? icon = find_button.image as Gtk.Image;
                                    if (icon != null) {
                                        icon.icon_name = Tatam.IconName.Symbolic.FOLDER_OPEN;
                                    }
                                }                                    
                            });
                    }
                    
                    box_2.pack_start(parent_button, false, false);
                    box_2.pack_start(location_entry, true, true);
                    box_2.pack_start(find_button, false, false);
                }

                finder_revealer = new Gtk.Revealer();
                {
                    Gtk.Paned finder_paned = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
                    {
                        sidebar = new Tatam.Sidebar();
                        {
                            sidebar.bookmark_directory_selected.connect((dir_path) => {
                                    location = dir_path;
                                });
                            sidebar.bookmark_del_button_clicked.connect((dir_path) => {
                                    return Tatam.Dialogs.confirm(Tatam.Text.CONFIRM_REMOVE_BOOKMARK, window);
                                });
                            sidebar.playlist_selected.connect((playlist_name, playlist_path) => {
                                    try {
                                        playlist_view.load_list_from_file(playlist_path);
                                    } catch (FileError e) {
                                        stderr.printf(@"FileError: $(e.message)\n");
                                    }
                                });
                            sidebar.playlist_del_button_clicked.connect((playlist_path) => {
                                    return Tatam.Dialogs.confirm(Tatam.Text.CONFIRM_REMOVE_PLAYLIST, window);
                                });
                            sidebar.file_chooser_called.connect(() => {
                                    string? dir_path = Tatam.Dialogs.choose_directory(window);
                                    if (dir_path != null) {
                                        location = dir_path;
                                    }
                                });
                            sidebar.bookmark_added.connect((file_path) => {

                                });
                        }
                        
                        finder = Tatam.Finder.create_default_instance();
                        {
                            finder.dir_changed.connect((path) => {
                                    location_entry.text = path;
                                });
                            finder.bookmark_button_clicked.connect((file_path) => {
                                    sidebar.add_bookmark(file_path);
                                });
                            finder.play_button_clicked.connect((path) => {
                                    setup_playlist(path, false);
                                    playlist_view.set_index(0);
                                    show_playlist();
                                    gst_player.play(playlist_view.get_file_info().path);
                                });
                            finder.add_button_clicked.connect((path) => {
                                    show_playlist();
                                    setup_playlist(path, true);
                                });
                        }

                        finder_paned.add1(sidebar);
                        finder_paned.add2(finder);
                        finder_paned.wide_handle = true;
                        finder_paned.position = sidebar.get_window().get_width();
                    }
                    
                    finder_revealer.child = finder_paned;
                    finder_revealer.reveal_child = true;
                    finder_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
                }
                
                controller = new Tatam.Controller();
                {
                    controller.artwork_size = uint.parse(options.get(Tatam.OptionKey.CONTROLLER_IMAGE_SIZE_MIN));
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

                        Gtk.Box box_4 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                        {
                            Gtk.Button save_button = new Gtk.Button.from_icon_name(Tatam.IconName.Symbolic.DOCUMENT_SAVE);
                            {
                                save_button.tooltip_text = Tatam.Text.TOOLTIP_SAVE_BUTTON;
                                save_button.clicked.connect(() => {
                                        Gee.List<string> file_path_list = new Gee.ArrayList<string>();
                                        for (int i = 0; i < playlist_view.get_list_size(); i++) {
                                            file_path_list.add(playlist_view.get_file_info_at_index(i).path);
                                        }
                                        string playlist_name = playlist_view.playlist_name;
                                        if (playlist_view.playlist_name == null) {
                                            save_playlist(file_path_list);
                                        } else if (sidebar.has_playlist(playlist_name)) {
                                            if (Tatam.Dialogs.confirm(Tatam.Text.CONFIRM_OVERWRITE.printf(playlist_name), window)) {
                                                overwrite_playlist(playlist_name, file_path_list);
                                            } else {
                                                save_playlist(file_path_list);
                                            }
                                        }
                                    });
                            }

                            box_4.pack_end(save_button, false, false);
                        }
                        
                        box_3.pack_start(playlist_view, true, true);
                        box_3.pack_start(box_4, false, false);
                    }

                    playlist_revealer.child = box_3;
                    playlist_revealer.reveal_child = false;
                    playlist_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
                }
                
                box_1.pack_start(box_2, false, false);
                box_1.pack_start(finder_revealer, true, true);
                box_1.pack_start(controller, false, false);
                box_1.pack_start(playlist_revealer, false, false);
            }

            window.add(box_1);
            window.set_title(Tatam.PROGRAM_NAME);
            window.set_default_size(700, 500);
            window.destroy.connect(this.quit);
            window.show_all();
        }
    }

    private void show_finder() {
        finder_revealer.reveal_child = true;
        box_1.set_child_packing(finder_revealer, true, true, 0, Gtk.PackType.START);
        playlist_revealer.reveal_child = false;
        box_1.set_child_packing(playlist_revealer, false, false, 0, Gtk.PackType.START);
        controller.artwork_size = uint.parse(options.get(Tatam.OptionKey.CONTROLLER_IMAGE_SIZE_MIN));
    }

    private void show_playlist() {
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
        print_file_info_pretty(info);
        debug("set_controller_artwork is completed");
    }

    private void setup_playlist(string path, bool append_mode) {
        try {
            print(@"setup playlist of $(path)\n");
            Gee.List<Tatam.FileInfo?> playlist = Tatam.Files.find_file_infos_recursively(path);
            print("playlist was loaded\n");

            if (!append_mode) {
                playlist_view.remove_all();
            }

            foreach (Tatam.FileInfo? file_info in playlist) {
                playlist_view.add_item(file_info);
            }

            controller.activate_buttons(!playlist_view.has_previous(), !playlist_view.has_next());
        } catch (FileError e) {
            stderr.printf(@"FileError: $(e.message)\n");
        }
    }

    private void save_playlist(Gee.List<string> file_path_list) {
        if (save_playlist_dialog == null) {
            Gtk.Entry playlist_name_entry;
            Gee.List<string> copy_of_list = file_path_list;
            save_playlist_dialog = new Gtk.Dialog.with_buttons(Tatam.PROGRAM_NAME + ": save playlist",
                                                               window,
                                                               Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                                               Tatam.Text.DIALOG_OK,
                                                               Gtk.ResponseType.ACCEPT,
                                                               Tatam.Text.DIALOG_CANCEL,
                                                               Gtk.ResponseType.CANCEL);
            {
                var save_playlist_dialog_hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
                {
                    var label = new Gtk.Label(Tatam.Text.PLAYLIST_SAVE_NAME);
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
                        playlist_name_entry.text = Tatam.Text.EMPTY;
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
        } catch (Error e) {
            stderr.printf(Tatam.Text.ERROR_WRITE_CONFIG);
            Process.exit(1);
        }
    }

    private void init_playlists_of_sidebar() {
        try {
            Tatam.DirectoryReader dreader = new Tatam.DirectoryReader(config_dir);
            dreader.file_found.connect((file) => {
                    if (file.get_basename().has_suffix(".m3u")) {
                        sidebar.add_playlist(remove_extension(file.get_basename()), file.get_path());
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
    
    private string get_playlist_path_from_name(string playlist_name) {
        return config_dir + "/" + playlist_name + ".m3u";
    }

    private string remove_extension(string file_name) {
        return file_name.substring(0, file_name.last_index_of_char('.'));
    }

    public static int main(string[] args) {
        init();
        Gst.init(ref args);
        Gtk.init(ref args);
        TatamApplication app = new TatamApplication(ref args);
        app.run();
        Gtk.main();
        return 0;
    }
}
