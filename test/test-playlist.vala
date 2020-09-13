using Gtk, Gst;

public class TestPlaylist {
    public static int main(string[] args) {
        Gst.init(ref args);
        Gtk.init(ref args);
        var tester = new TestPlaylist();
        tester.run();
        Gtk.main();
        return 0;
    }

    private Window window;
    private Tatam.PlaylistBox playlist;
    
    public TestPlayGee.List() {
        window = new Gtk.Window();
        {
            Box box_1 = new Box(Orientation.VERTICAL, 0);
            {
                Box box_2 = new 

                playlist = new Tatam.PlaylistBox();
                {

                }

                box_1.pack_start(playlist, true, true);
            }

            window.add
            window.destroy.connect(Gtk.main_quit);
        }
    }

    public void run() {

    }

    
}
