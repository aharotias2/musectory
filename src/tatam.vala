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
Gee.List<string> dirs;
CompareFunc<string> string_compare_func;
CopyFunc<Tatam.FileInfo?> file_info_copy_func;
string current_dir = null;

//--------------------------------------------------------------------------------------
// global variable for playing music
//--------------------------------------------------------------------------------------
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

    dirs = new Gee.ArrayList<string>();

    //----------------------------------------------------------------------------------
    // reading config files
    //----------------------------------------------------------------------------------
    string config_dir_path = Environment.get_home_dir() + "/." + PROGRAM_NAME;
    string config_file_path = config_dir_path + "/settings.ini";
    string config_file_contents;
    debug("config_dir: %s", config_dir_path);
    Tatam.Options options = new Tatam.Options();
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
            GLib.FileUtils.get_contents(config_file_path, out config_file_contents);

            string[] config_file_lines = config_file_contents.split("\n", -1);

            foreach (string line in config_file_lines) {
                string[] pair = line.split("=", 2);
                switch (pair[0]) {
                case "dir":
                    dirs.add(pair[1]);
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
            dirs.add(Environment.get_home_dir() + "/" + Text.DIR_NAME_MUSIC);
        }
    } catch(GLib.Error e) {
        dirs.add(Environment.get_home_dir() + "/" + Text.DIR_NAME_MUSIC);
    }

    //----------------------------------------------------------------------------------
    // create temporary working directory
    //----------------------------------------------------------------------------------
    GLib.File tmp_dir = GLib.File.new_for_path("/tmp/" + PROGRAM_NAME);
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
    Gst.init(ref args);
    
    //----------------------------------------------------------------------------------
    // Creating the main window
    //-----------------------------------------------------
    -----------------------------
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
