public class TestMetadata {
    private static Posix.FILE output;
    private static GLib.MainLoop main_loop;

    public static int main(string[] args) {
        output = Posix.FILE.fdopen(1, "w");
        set_print_handler((text) => output.printf(text));

        Gst.init(ref args);
        main_loop = new GLib.MainLoop();
        try {
            string file_path = choose_file("/var/run/media/ta/TOSHIBAEXT/Music4");
            run_test.begin(file_path);
            main_loop.run();
            return 0;
        } catch (GLib.Error e) {
            stderr.printf(@"Error: %s\n", e.message);
            return 1;
        }
    }

    private static async void run_test(string file_path) throws GLib.Error {
        Tatam.FileInfoAdapter file_info_adapter = new Tatam.FileInfoAdapter();
        Tatam.FileInfo file_info = yield file_info_adapter.read_metadata_from_path(file_path);
        Json.Node json = Json.from_string(file_info.to_string());
        print("%s\n", Json.to_string(json, true));
        main_loop.quit();
    }

    private static string choose_file(string dir_path) throws GLib.Error, GLib.FileError {
        Tatam.DirectoryReader reader = new Tatam.DirectoryReader(dir_path);
        List<string> dir_list = new List<string>();
        List<string> file_list = new List<string>();

        reader.directory_found.connect((dir) => {
                dir_list.append(dir.get_basename());
                return true;
            });

        reader.file_found.connect((file) => {
                file_list.append(file.get_basename());
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
        if (num <= dir_list.length()) {
            string child_name = dir_list.nth_data(num - 1);
            return choose_file(dir_path + "/" + child_name);
        } else {
            string child_name = file_list.nth_data(num - 1 - dir_list.length());
            debug(@"$(dir_path)/$(child_name)");
            return dir_path + "/" + child_name;
        }
    }
}
