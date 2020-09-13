public class TestFilePath : TestBase {
    public static int main(string[] args) {
        init();
        TestFilePath tester = new TestFilePath();
        tester.run();
        return 0;
    }

    public void run() {
        test01();
    }

    private void test01() {
        try {
            string file_path = choose_file("/var/run/media/ta/TOSHIBAEXT/Music4");
            string cache_path = Tatam.FilePathUtils.make_cache_path(file_path);
            print(@"Cache to \"$(cache_path)\" from \"$(file_path)\"\n");
        } catch (GLib.FileError e) {
            stderr.printf(@"FileError: $(e.message)\n");
        } catch (GLib.Error e) {
            stderr.printf(@"Error: $(e.message)\n");
        }
    }
}
