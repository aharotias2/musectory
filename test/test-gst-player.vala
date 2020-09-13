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

public class TestGstPlayer {
    private static Posix.FILE output;
    private Tatam.GstPlayer? gst_player;
    private Gtk.Window window;
    private Gtk.Entry location;
    private Gtk.Button find_button;
    private Tatam.Controller controller;
    private bool playing;
    private Tatam.FileInfoAdapter? file_info_reader;
    private Tatam.FileInfo? info;
    
    private void construct_window() {
        playing = false;
        window = new Gtk.Window();
        {
            Gtk.Box box_1 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            {
                Gtk.Box box_2 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                {
                    location = new Gtk.Entry();
                    {
                        location.activate.connect(() => {
                                set_controller_artwork.begin();
                            });
                    }
                    
                    find_button = new Gtk.Button.from_icon_name("document-open-symbolic");
                    {
                        find_button.clicked.connect(() => {
                                location.text = Tatam.Dialogs.choose_file(window);
                                location.activate();
                            });
                    }
                    
                    box_2.pack_start(location, true, true);
                    box_2.pack_start(find_button, false, false);
                }

                controller = new Tatam.Controller();
                {
                    controller.play_button_clicked.connect(() => {
                            if (!playing) {
                                gst_player.play(location.text);
                            } else {
                                gst_player.unpause();
                            }
                        });
                    controller.pause_button_clicked.connect(() => {
                            gst_player.pause();
                        });
                    controller.time_position_changed.connect((new_value) => {
                            gst_player.set_position(new Tatam.SmallTime.from_milliseconds((uint) new_value));
                        });
                    controller.volume_changed.connect((value) => {
                            gst_player.volume = value;
                        });
                }
                
                box_1.pack_start(box_2, false, false);
                box_1.pack_start(controller, false, false);
            }

            window.add(box_1);
            window.set_default_size(600,10);
            window.destroy.connect(Gtk.main_quit);
            window.show_all();
        }
    }

    private void setup_gst_player() {
        gst_player = new Tatam.GstPlayer();
        gst_player.volume = 0.5;
        gst_player.error_occured.connect((error) => {
                stderr.printf(@"Error: $(error.message)\n");
            });
        gst_player.finished.connect(() => {
                playing = false;
            });
        gst_player.unpaused.connect(() => {
                print("Unpaused\n");
            });
        gst_player.paused.connect(() => {
                print("Paused\n");
            });
    }

    private async void set_controller_artwork() {
        new Thread<int>(null, () => {
                gst_player.quit();
                info = file_info_reader.read_metadata_from_path(location.text);
                controller.music_total_time = info.time_length.milliseconds;
                controller.activate_buttons(true, true);
                controller.set_artwork(info.artwork);
                Idle.add(set_controller_artwork.callback);
                return 0;
            });
        yield;
    }
    
    private void setup_file_info_adapter() {
        file_info_reader = new Tatam.FileInfoAdapter();
    }
    
    public TestGstPlayer() {
        playing = false;
        construct_window();
        setup_gst_player();
        setup_file_info_adapter();
    }

    public static int main(string[] args) {
        output = Posix.FILE.fdopen(1, "w");
        set_print_handler((text) => output.printf(text));
        Gst.init(ref args);
        Gtk.init(ref args);
        TestGstPlayer tester = new TestGstPlayer();
        Gtk.main();
        return 0;
    }
}
