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

using Gtk, Tatam;

//--------------------------------------------------------------------------------------
// Delegates
//--------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------
// Constants
//--------------------------------------------------------------------------------------

//--------------------------------------------------------------------------------------
// global variables for file management
//--------------------------------------------------------------------------------------
List<string> dirs;
CompareFunc<string> string_compare_func;
CopyFunc<Tatam.FileInfo?> file_info_copy_func;
string current_dir = null;

//--------------------------------------------------------------------------------------
// global variable for playing music
//--------------------------------------------------------------------------------------
Music music;

string music_total_time;
double music_total_time_seconds;
double music_time_position;
Gdk.Pixbuf current_playing_artwork;

//--------------------------------------------------------------------------------------
// global variables for images
//--------------------------------------------------------------------------------------
int max_width;
int max_height;
int artwork_max_size;

//--------------------------------------------------------------------------------------
// global variables for widgets
//--------------------------------------------------------------------------------------
Tatam.Window main_win;
bool print_message_of_send_mplayer_command;

int main(string[] args) {
    if (Posix.system("mplayer") != 0) {
        stderr.printf(Text.ERROR_NO_MPLAYER);
        Process.exit(1);
    }

    dirs = new List<string>();

    //----------------------------------------------------------------------------------
    // reading config files
    //----------------------------------------------------------------------------------
    string config_dir_path = Environment.get_home_dir() + "/." + PROGRAM_NAME;
    string config_file_path = config_dir_path + "/settings.ini";
    string config_file_contents;
    debug("config_dir: %s", config_dir_path);

    options.ao_type = "pulse";
    options.thumbnail_size = 80;
    options.show_thumbs_at = ShowThumbsAt.ALBUMS;
    options.playlist_image_size = 52;
    options.icon_size = 128;
    options.last_playlist_name = "";
    
    current_dir = null;

    try {
        if (!GLib.FileUtils.test(config_dir_path, FileTest.EXISTS)) {
            GLib.File dir = GLib.File.new_for_path(config_dir_path);
            dir.make_directory_with_parents();
        }
        
        if (GLib.FileUtils.test(config_file_path, FileTest.EXISTS)) {
            FileUtils.get_contents(config_file_path, out config_file_contents);

            string[] config_file_lines = config_file_contents.split("\n", -1);

            foreach (string line in config_file_lines) {
                string[] pair = line.split("=", 2);
                switch (pair[0]) {
                case "dir":
                    dirs.append(pair[1]);
                    break;

                case "thumbnail_size":
                    options.thumbnail_size = int.parse(pair[1]);
                    break;

                case "cwd":
                    current_dir = pair[1];
                    break;

                case "playlist_image_size":
                    options.playlist_image_size = int.parse(pair[1]);
                    break;

                case "icon_size":
                    options.icon_size = int.parse(pair[1]);
                    break;

                case "last_playlist_name":
                    options.last_playlist_name = pair[1];
                    break;
                }
            }
        }

        if (dirs.length() == 0) {
            dirs.append(Environment.get_home_dir() + "/" + Text.DIR_NAME_MUSIC);
        }
    } catch(GLib.Error e) {
        dirs.append(Environment.get_home_dir() + "/" + Text.DIR_NAME_MUSIC);
    }

    //----------------------------------------------------------------------------------
    // create temporary working directory
    //----------------------------------------------------------------------------------
    GLib.File tmp_dir = File.new_for_path("/tmp/" + PROGRAM_NAME);
    if (!GLib.FileUtils.test("/tmp/" + PROGRAM_NAME, FileTest.EXISTS)) {
        try {
            tmp_dir.make_directory();
        } catch(GLib.Error e) {
            stderr.printf(Text.ERROR_FAIL_TMP_DIR);
            Process.exit(1);
        }
    }

    //----------------------------------------------------------------------------------
    // Setting place of a CSS file
    //----------------------------------------------------------------------------------
    string css_path = config_dir_path + "/main.css";
    if (!GLib.FileUtils.test(css_path, FileTest.EXISTS)) {
        FileUtils.set_contents(css_path, DEFAULT_CSS);
    }
        
    Gtk.init(ref args);

    //----------------------------------------------------------------------------------
    // Creating music player manager (control for MPlayer)
    //----------------------------------------------------------------------------------
    music = new Music();
    {
        music.on_quit.connect((pid, status) => {
                time_bar.set_value(0.0);
                time_label_set(0);

                controller.play_pause_button_state = Tatam.Controller.PlayPauseButtonState.PLAY;
            });
    
        music.on_start.connect((track_number, file_path) => {
                debug("on start func start");

                Tatam.FileInfo file_info = playlist.nth_track_data(track_number);

                music_title.label = (file_info.title != null) ? file_info.title : file_info.name;
                header_bar.set_title(music_title.label);
                music_total_time = file_info.time_length;
                SmallTime small_time = new SmallTime.from_string(music_total_time);
                music_total_time_seconds = small_time.milliseconds / 1000;
                music_time_position = 0.0;
                controller.music_total_time_seconds = music_total_time_seconds;
                Timeout.add(100, () => {
                        if (track_number != music.get_current_track_number() || !music.playing) {
                            return Source.REMOVE;
                        }

                        if (!music.paused) {
                            music_time_position += 0.1;
                            controller.set_time(music_time_position);
                        }
                        return Source.CONTINUE;
                    });

                controller.play_pause_button_state = Tatam.Controller.PlayPauseButtonState.PAUSE;

                play_pause_button.sensitive = true;
                next_track_button.sensitive = !playlist.track_is_last();
                prev_track_button.sensitive = true;

                playlist.set_track(track_number);
                
                debug("artwork_max_size: " + artwork_max_size.to_string());
                current_playing_artwork = file_info.artwork;
                if (current_playing_artwork != null) {
                    artwork.set_from_pixbuf(MyUtils.PixbufUtils.scale(current_playing_artwork,
                                                                              options.thumbnail_size));
                    if (!music_view_artwork.visible) {
                        artwork_button.visible = true;
                        debug("make artwork button visible");
                    }
                    Idle.add(() => {
                            debug("enter timeout artwork size");
                            int size = int.min(music_view_container.get_allocated_width(),
                                               music_view_container.get_allocated_height());
                            music_view_artwork.pixbuf = MyUtils.PixbufUtils.scale(current_playing_artwork,
                                                                                  size);
                            debug("music view artwork size: " + size.to_string());
                            return Source.REMOVE;
                        });
                } else {
                    artwork_button.visible = false;
                    music_view_artwork.set_from_icon_name(IconName.AUDIO_FILE, IconSize.LARGE_TOOLBAR);
                }

            });

        music.on_end.connect((track_number, track_name) => {
                // ???
                //playlist.set_track(-1);
            });
    }
    
    //----------------------------------------------------------------------------------
    // Creating the main window
    //----------------------------------------------------------------------------------
    main_win = new Tatam.Window(options);

    Gtk.main();

    //----------------------------------------------------------------------------------
    // Finishing this program
    //----------------------------------------------------------------------------------
    config_file_contents = """
thumbnail_size=$(options.thumbnail_size)
cwd=$(current_dir)
playlist_image_size=$(options.playlist_image_size)
icon_size=$(options.icon_size)
playlist_name=$(options.last_playlist_name)
""";

    foreach (string dir in dirs) {
        config_file_contents += "dir=" + dir + "\n";
    }

    try {
        GLib.FileUtils.set_contents(config_file_path, config_file_contents);
    } catch (GLib.Error e) {
        stderr.printf(Text.ERROR_WRITE_CONFIG);
        Process.exit(1);
    }

    return 0;
}
