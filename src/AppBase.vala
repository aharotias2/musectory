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

public class AppBase {
    protected static Posix.FILE output;
    protected static bool debugging_on;

    public static void init() {
        output = Posix.FILE.fdopen(1, "w");
        set_print_handler((text) => output.printf(text));
        debugging_on = Environment.get_variable("G_MESSAGES_DEBUG") == "all";
    }

    protected static string choose_file(string dir_path) throws GLib.Error, GLib.FileError {
        Tatam.DirectoryReader reader = new Tatam.DirectoryReader(dir_path);
        Gee.List<string> dir_list = new Gee.ArrayList<string>();
        Gee.List<string> file_list = new Gee.ArrayList<string>();

        reader.directory_found.connect((dir) => {
            dir_list.add(dir.get_basename());
            return true;
        });

        reader.file_found.connect((file) => {
            file_list.add(file.get_basename());
            return true;
        });

        reader.run();

        int i = 1;

        print("Directory %s\n", dir_path);
        print("Directories\n");
        foreach (string path in dir_list) {
            stdout.printf("\t%3d : %s\n", i, path);
            i++;
        }

        print("Files\n");
        foreach (string path in file_list) {
            stdout.printf("\t%3d : %s\n", i, path);
            i++;
        }

        stdout.printf("Select a number: ");
        string? line = null;
        line = stdin.read_line();
        int num = int.parse(line);
        stdout.printf("\n");
        if (num == 0) {
            return dir_path;
        } else if (num <= dir_list.size) {
            string child_name = dir_list[num - 1];
            return choose_file(dir_path + "/" + child_name);
        } else {
            num -= dir_list.size;
            if (num <= file_list.size) {
                string child_name = file_list[num - 1];
                debug(@"$(dir_path)/$(child_name)");
                return dir_path + "/" + child_name;
            }
        }
        return "";
    }

    protected void print_file_info_pretty(Tatam.FileInfo? file_info) {
        if (file_info != null) {
            try {
                Json.Node json = Json.from_string(file_info.to_string());
                print("%s\n", Json.to_string(json, true));
            } catch (GLib.Error e) {
                stderr.printf(@"GLib.Error: $(e.message)\n");
            }
        } else {
            stderr.printf("file_info is null\n");
        }
    }

    protected void setup_css(Gtk.Window window, string css_path) {
        if (GLib.FileUtils.test(css_path, FileTest.EXISTS)) {
            debug("css exists at %s", css_path);
            Gdk.Screen win_screen = window.get_screen();
            Gtk.CssProvider css_provider = new Gtk.CssProvider();
            try {
                css_provider.load_from_path(css_path);
            } catch (Error e) {
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
