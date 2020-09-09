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
                                file_info_reader.read_metadata_from_path.begin(
                                    location.text,
                                    (res, obj) => {
                                        info = file_info_reader.read_metadata_from_path.end(obj);
                                        controller.music_total_time = info.time_length.milliseconds;
                                        controller.activate_buttons(true, true);
                                        controller.set_artwork(info.artwork);
                                    });
                            });
                    }
                    
                    find_button = new Gtk.Button.from_icon_name("document-open-symbolic");
                    {
                        find_button.clicked.connect(() => {
                                location.text = choose_file();
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
                }
                
                box_1.pack_start(box_2, false, false);
                box_1.pack_start(controller, false, false);
            }

            window.add(box_1);
            window.destroy.connect(Gtk.main_quit);
            window.show_all();
        }
    }

    private void setup_gst_player() {
        gst_player = new Tatam.GstPlayer();
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

    private void setup_file_info_adapter() {
        file_info_reader = new Tatam.FileInfoAdapter();
    }
    
    public TestGstPlayer() {
        playing = false;
        construct_window();
        setup_gst_player();
        setup_file_info_adapter();
    }

    private string? choose_file() {
        string? file_path = null;
        var file_chooser = new Gtk.FileChooserDialog(
            Tatam.Text.DIALOG_OPEN_FILE, window,
            Gtk.FileChooserAction.OPEN,
            Tatam.Text.DIALOG_CANCEL, Gtk.ResponseType.CANCEL,
            Tatam.Text.DIALOG_OPEN, Gtk.ResponseType.ACCEPT
            );
        if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
            file_path = file_chooser.get_filename();
        }
        file_chooser.destroy ();
        return file_path;
    }
    
    public static int main(string[] args) {
        output = Posix.FILE.fdopen(1, "w");
        set_print_handler((text) => output.printf(text));
        Gst.init(ref args);
        Gtk.init(ref args);
        TestGstPlayer test = new TestGstPlayer();
        Gtk.main();
        return 0;
    }
}
