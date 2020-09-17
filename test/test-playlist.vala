using Gtk, Gst;

public class TestPlaylist : TestBase {
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
    private Entry location_entry;
    
    public TestPlaylist() {
        window = new Gtk.Window();
        {
            Box box_1 = new Box(Orientation.VERTICAL, 0);
            {
                Box box_2 = new Box(Orientation.HORIZONTAL, 0);
                {
                    location_entry = new Entry();
                    {
                        location_entry.activate.connect(() => {
                                if (GLib.FileUtils.test(location_entry.text, FileTest.IS_DIR)) {
                                    var file_list = Tatam.Files.get_file_info_list_in_dir(location_entry.text);
                                    playlist.append_list(file_list);
                                }
                            });
                    }

                    Button find_button = new Button.from_icon_name("folder-open-symbolic");
                    {
                        find_button.clicked.connect(() => {
                                string? dir_path = Tatam.Dialogs.choose_directory(window);
                                if (dir_path != null) {
                                    location_entry.text = dir_path;
                                    location_entry.activate();
                                }
                            });
                    }

                    box_2.pack_start(location_entry, true, true);
                    box_2.pack_start(find_button, false, false);
                }

                playlist = new Tatam.PlaylistBox();
                {
                    playlist.image_size = 48;
                    playlist.changed.connect(() => {
                            print("Playlist changed!\n");
                        });
                }

                box_1.pack_start(box_2, false, false);
                box_1.pack_start(playlist, true, true);
            }

            window.add(box_1);
            window.destroy.connect(Gtk.main_quit);
            window.set_default_size(500, 700);
        }
    }

    public void run() {
        window.show_all();
    }
}
