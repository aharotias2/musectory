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

    private Tatam.GstPlayer? gst_player;
    private Gtk.Window window;
    private Gtk.Entry location_entry;
    private Gtk.Button parent_button;
    private Gtk.Button find_button;
    private Tatam.Controller controller;
    private Tatam.PlaylistBox playlist_view;
    private Gtk.Revealer finder_revealer;
    private Gtk.Revealer playlist_revealer;
    private Tatam.Finder finder;
    
    private bool playing;
    private Tatam.FileInfoAdapter? file_info_reader;
    
    private string location {
        get {
            return location_entry.text;
        }
        set {
            location_entry.text = value;
        }
    }
    
    public TestGstPlayer() {
        playing = false;
        setup_gst_player();
        setup_file_info_adapter();
        construct_window();
        setup_css(window, options.get("-c"));
        finder.change_dir.begin(options.get("-d"));
    }

    private void construct_window() {
        playing = false;
        window = new Gtk.Window();
        {
            Gtk.Box box_1 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            {
                Gtk.Box box_2 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                {
                    parent_button = new Gtk.Button.from_icon_name("go-up");
                    {
                        parent_button.clicked.connect(() => {
                                File dir = File.new_for_path(location).get_parent();
                                location = dir.get_path();
                                finder.change_dir.begin(location);
                            });
                    }
                    
                    location_entry = new Gtk.Entry();
                    {
                        location_entry.activate.connect(() => {
                                location = location_entry.text;
                                finder.change_dir.begin(location);
                            });
                    }
                    
                    find_button = new Gtk.Button.from_icon_name("folder-open-symbolic");
                    {
                        find_button.clicked.connect(() => {
                                if (!finder_revealer.child_revealed) {
                                    print("Call direcotry chooser\n");
                                    finder_revealer.reveal_child = true;
                                    finder_revealer.visible = true;
                                    playlist_revealer.reveal_child = false;
                                    playlist_revealer.visible = false;
                                    Gtk.Image? icon = find_button.image as Gtk.Image;
                                    if (icon != null) {
                                        icon.icon_name = "window-close-symbolic";
                                    }
                                } else {
                                    finder_revealer.reveal_child = false;
                                    finder_revealer.visible = false;
                                    playlist_revealer.reveal_child = true;
                                    playlist_revealer.visible = true;
                                    Gtk.Image? icon = find_button.image as Gtk.Image;
                                    if (icon != null) {
                                        icon.icon_name = "folder-open-symbolic";
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
                    finder = Tatam.Finder.create_default_instance();

                    finder.dir_changed.connect((path) => {
                            location = path;
                        });

                    finder.play_button_clicked.connect((path) => {
                            finder_revealer.reveal_child = false;
                            finder_revealer.visible = false;
                            playlist_revealer.reveal_child = true;
                            playlist_revealer.visible = true;
                            setup_playlist(path, false);
                            gst_player.play(playlist_view.get_current_track_file_info().path);
                        });

                    finder.add_button_clicked.connect((path) => {
                            finder_revealer.reveal_child = false;
                            finder_revealer.visible = false;
                            playlist_revealer.reveal_child = true;
                            playlist_revealer.visible = true;
                            setup_playlist(path, true);
                        });
                    
                    finder_revealer.child = finder;
                    finder_revealer.reveal_child = true;
                    finder_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
                }

                controller = new Tatam.Controller();
                {
                    controller.artwork_size = 72;
                    controller.play_button_clicked.connect(() => {
                            debug("controller.play_button_clicked");
                            if (!playing) {
                                gst_player.play(playlist_view.get_current_track_file_info().path);
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
                            if (!playlist_view.track_is_last()) {
                                playlist_view.move_to_next_track();
                                set_controller_artwork();
                                gst_player.play(playlist_view.get_current_track_file_info().path);
                            }
                        });
                    controller.prev_button_clicked.connect(() => {
                            debug("controller.prev_button_clicked");
                            if (controller.music_current_time > 1000) {
                                controller.music_current_time = 0;
                                gst_player.quit();
                                gst_player.play(playlist_view.get_current_track_file_info().path);
                            } else if (!playlist_view.track_is_first()) {
                                playlist_view.move_to_prev_track();
                                set_controller_artwork();
                                gst_player.play(playlist_view.get_current_track_file_info().path);
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

                playlist_revealer = new Gtk.Revealer();
                {
                    Gtk.Box box_3 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
                    {
                        playlist_view = new Tatam.PlaylistBox();
                        {
                            playlist_view.image_size = 48;
                            playlist_view.row_activated.connect((index, file_info) => {
                                    gst_player.quit();
                                    gst_player.play(playlist_view.get_current_track_file_info().path);
                                });
                        }
                        
                        box_3.pack_start(playlist_view, true, true);
                    }

                    playlist_revealer.child = box_3;
                    playlist_revealer.reveal_child = false;
                    playlist_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
                }
                
                box_1.pack_start(box_2, false, false);
                box_1.pack_start(finder_revealer, true, true);
                box_1.pack_start(controller, false, false);
                box_1.pack_start(playlist_revealer, true, true);
            }

            window.add(box_1);
            window.set_default_size(700, 500);
            window.destroy.connect(Gtk.main_quit);
            window.show_all();
        }

        playlist_revealer.visible = false;
    }

    private void setup_gst_player() {
        gst_player = new Tatam.GstPlayer();
        gst_player.volume = 0.5;
        gst_player.started.connect(() => {
                debug("gst_player.started was called");
                set_controller_artwork();
                controller.play_pause_button_state = Tatam.Controller.PlayPauseButtonState.PLAY;
            });
        gst_player.error_occured.connect((error) => {
                debug("gst_player.error_occured was called");
                stderr.printf(@"Error: $(error.message)\n");
            });
        gst_player.finished.connect(() => {
                debug("gst_player.finished was called");
                if (!playlist_view.track_is_last()) {
                    debug("playlist has next track");
                    playlist_view.move_to_next_track();
                    debug("playlist moved to next track");
                    string next_path = playlist_view.get_current_track_file_info().path;
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
        Tatam.FileInfo? info = playlist_view.get_current_track_file_info();
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
        print_file_info_pretty(info);
        debug("set_controller_artwork is completed");
    }

    private void setup_file_info_adapter() {
        file_info_reader = new Tatam.FileInfoAdapter();
    }

    private void setup_playlist(string path, bool append_mode) {
        try {
            print(@"setup playlist of $(path)\n");
            Gee.List<Tatam.FileInfo?> playlist = Tatam.Files.find_file_infos_recursively(path);
            print("playlist was loaded\n");

            if (!append_mode) {
                playlist_view.clear();
            }

            foreach (Tatam.FileInfo? file_info in playlist) {
                playlist_view.add_item(file_info);
            }

            controller.activate_buttons(playlist_view.track_is_first(), playlist_view.track_is_last());
        } catch (FileError e) {
            stderr.printf(@"FileError: $(e.message)\n");
        }
    }

    public static int main(string[] args) {
        try {
            init();
            options = parse_args(ref args);
            Gst.init(ref args);
            Gtk.init(ref args);
            TestGstPlayer tester = new TestGstPlayer();
            Gtk.main();
            return 0;
        } catch (Tatam.Error e) {
            stderr.printf(@"Tatam Error: $(e.message)\n");
            return 1;
        }
    }
}
