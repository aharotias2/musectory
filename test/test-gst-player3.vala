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

public class TestGstPlayer : TestBase {
    private static Gee.Map<string, string> options;
    private static Posix.FILE output;

    private Tatam.GstPlayer? gst_player;
    private Gtk.Window window;
    private Gtk.Entry location_entry;
    private Gtk.Button find_button;
    private Tatam.Controller controller;
    private Gtk.TreeStore store;
    private Tatam.PlaylistBox playlist_view;

    private bool playing;
    private Tatam.FileInfoAdapter? file_info_reader;
    
    private string location {
        get {
            return location_entry.text;
        }
        set {
            location_entry.text = value;
            setup_playlist(location_entry.text);
        }
    }
    
    private void construct_window() {
        playing = false;
        window = new Gtk.Window();
        {
            Gtk.Box box_1 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            {
                Gtk.Box box_2 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                {
                    location_entry = new Gtk.Entry();
                    {
                        location_entry.activate.connect(() => {
                                location = location_entry.text;
                            });
                    }
                    
                    find_button = new Gtk.Button.from_icon_name("folder-open-symbolic");
                    {
                        find_button.clicked.connect(() => {
                                print("Call direcotry chooser\n");
                                location_entry.text = Tatam.Dialogs.choose_directory(window);
                                location_entry.activate();
                            });
                    }
                    
                    box_2.pack_start(location_entry, true, true);
                    box_2.pack_start(find_button, false, false);
                }

                controller = new Tatam.Controller();
                {
                    controller.artwork_size = 72;
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
                                debug(">");
                                playlist_view.next();
                                debug(">");
                                set_controller_artwork();
                                debug(">");
                                gst_player.play(playlist_view.get_file_info().path);
                                debug(">");
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
                }

                Gtk.Box box_3 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
                {
                    Gtk.ScrolledWindow playlist_scroll = new Gtk.ScrolledWindow(null, null);
                    {
                        playlist_view = new Tatam.PlaylistBox();
                        {
                            playlist_view.image_size = 48;

                            playlist_view.item_activated.connect((index, file_info) => {
                                    
                                });
                        }
                        
                        playlist_scroll.add(playlist_view);
                    }

                    box_3.pack_start(playlist_scroll, true, true);
                }
                
                box_1.pack_start(box_2, false, false);
                box_1.pack_start(controller, false, false);
                box_1.pack_start(box_3, true, true);
            }

            window.add(box_1);
            window.set_default_size(600, 500);
            window.destroy.connect(Gtk.main_quit);
            window.show_all();
        }
    }

    private void setup_gst_player() {
        gst_player = new Tatam.GstPlayer();
        gst_player.volume = 0.5;
        gst_player.started.connect(() => {
                debug("gst_player.started was called");
                set_controller_artwork();
                controller.play_pause_button_state = Tatam.ControllerState.PLAY;
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
                }
            });
        gst_player.unpaused.connect(() => {
                print("gst_player.unpaused was called\n");
            });
        gst_player.paused.connect(() => {
                print("gst_player.paused was called\n");
            });
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

    private void setup_file_info_adapter() {
        file_info_reader = new Tatam.FileInfoAdapter();
    }

    public TestGstPlayer() {
        playing = false;
        construct_window();
        setup_gst_player();
        setup_css(window, options.get("-c"));
        setup_file_info_adapter();
    }

    private void setup_playlist(string path) {
        try {
            print(@"setup playlist of $(path)\n");
            Gee.List<Tatam.FileInfo?> playlist = Tatam.Files.find_file_infos_recursively(path);
            print("playlist was loaded\n");

            foreach (var info in playlist) {
                print(info.path + "\n");
            }
            print("list is ok\n");

            playlist_view.remove_all();
            foreach (Tatam.FileInfo? file_info in playlist) {
                playlist_view.add_item(file_info);
            }

            controller.activate_buttons(!playlist_view.has_previous(), !playlist_view.has_next());
        } catch (FileError e) {
            stderr.printf(@"FileError: $(e.message)\n");
        }
    }
    
    public static int main(string[] args) {
        output = Posix.FILE.fdopen(1, "w");
        set_print_handler((text) => output.printf(text));
        options = parse_args(ref args);
        Gst.init(ref args);
        Gtk.init(ref args);
        TestGstPlayer tester = new TestGstPlayer();
        Gtk.main();
        return 0;
    }
}
