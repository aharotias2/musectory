public class TestMetadata {
    private static Posix.FILE output;

    public static int main(string[] args) {
        output = Posix.FILE.fdopen(1, "w");
        set_print_handler((text) => output.printf(text));

        try {
            string file_path = choose_file("/home/ta");
            run_test(file_path);
            return 0;
        } catch (GLib.Error e) {
            stderr.printf(@"Error: %s\n", e.message);
            return 1;
        }
    }

    private static void run_test(string file_path) throws GLib.Error {
        File file = File.new_for_path(file_path);
        FileInfo file_info = file.query_info("standard::*", 0);
        print("Selected file is : %s\n", file.get_path());
        print("Mime-Type is : %s\n", file_info.get_content_type());
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
