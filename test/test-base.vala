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
            Json.Node json = Json.from_string(file_info.to_string());
            print("%s\n", Json.to_string(json, true));
        } else {
            stderr.printf("file_info is null\n");
        }
    }
}
