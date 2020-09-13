public class TestMetadata : TestBase {
    public static int main(string[] args) {
        init();
        try {
            run_test();
            return 0;
        } catch (GLib.Error e) {
            stderr.printf(@"GLib.Error: $(e.message)\n");
            return 1;
        }
    }

    private static void run_test() throws GLib.Error {
        string file_path = choose_file("/home/ta");
        File file = File.new_for_path(file_path);
        GLib.FileInfo file_info = file.query_info("standard::*", 0);
        print("Selected file is : %s\n", file.get_path());
        print("Mime-Type is : %s\n", file_info.get_content_type());
    }
}
