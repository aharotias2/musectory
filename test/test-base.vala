public class TestBase {
    private static Posix.FILE output;

    public static void init() {
        output = Posix.FILE.fdopen(1, "w");
        set_print_handler((text) => output.printf(text));
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

    protected static Gee.Map<string, string> parse_args(ref unowned string[] args) throws Tatam.Error {
        Gee.Map<string, string> map = new Gee.HashMap<string, string>();
        {
            for (int i = 0; i < args.length; i++) {
                switch (args[i]) {
                case "-c":
                    File css_file = File.new_for_path(args[i + 1]);
                    if (css_file.query_exists()) {
                        map.set(args[i], css_file.get_path());
                        i++;
                    } else {
                        throw new Tatam.Error.FILE_DOES_NOT_EXISTS(Tatam.Text.ERROR_FILE_DOES_NOT_EXISTS);
                    }
                    break;
                case "-d":
                    File directory = File.new_for_path(args[i + 1]);
                    if (directory.query_exists()) {
                        map.set(args[i], directory.get_path());
                    } else {
                        throw new Tatam.Error.FILE_DOES_NOT_EXISTS(Tatam.Text.ERROR_FILE_DOES_NOT_EXISTS);
                    }
                    i++;
                    break;
                }
            }
        }

        if (!map.has_key("-c")) {
            map.set("-c", File.new_for_path("./tatam.css").get_path());
        }

        if (!map.has_key("-d")) {
            map.set("-d", File.new_for_path("~").get_path());
        }
        
        return map;
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
                stderr.printf(Tatam.Text.ERROR_CREATE_WINDOW);
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
