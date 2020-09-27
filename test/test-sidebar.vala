class TestWindow : Gtk.Window {
    private Tatam.Sidebar sidebar;
    
    public TestWindow() {
        sidebar = new Tatam.Sidebar();
        {
            sidebar.bookmark_directory_selected.connect((dir_path) => {
                    print("bookmark was selected (%s)\n", dir_path);
                });

            sidebar.bookmark_del_button_clicked.connect((dir_path) => {
                    print("delete bookmark (%s) was selected\n", dir_path);
                    return true;
                });

            sidebar.playlist_selected.connect((playlist_name, playlist_path) => {
                    print("playlist name (%s), path (%s)\n", playlist_name, playlist_path);
                });

            sidebar.playlist_del_button_clicked.connect((playlist_path) => {
                    print("delete playlist (%s) button was clicked\n", playlist_path);
                    return true;
                });

            sidebar.file_chooser_called.connect(() => {
                    print("File chooser button was clicked\n");
                });

            sidebar.bookmark_added.connect((file_path) => {
                    print("Add bookmark (%s) button was clicked\n", file_path);
                });
        }

        add(sidebar);
        set_default_size(250, 400);
        destroy.connect(Gtk.main_quit);
        show_all();
    }

    public void setup_bookmarks() {
        sidebar.add_bookmark("/home/ta/Work/tatam");
        sidebar.add_bookmark("/home/ta/Work/tatap");
        sidebar.add_bookmark("/home/ta/Work/tataw");
        sidebar.add_playlist("test-playlist-01", "/home/ta/Work/tatap/test/files/test-playlist-01.m3u");
        sidebar.add_playlist("test-playlist-02", "/home/ta/Work/tatap/test/files/test-playlist-02.m3u");
        sidebar.add_playlist("test-playlist-03", "/home/ta/Work/tatap/test/files/test-playlist-03.m3u");
    }
}

int main(string[] args) {
    Gtk.init(ref args);
    TestWindow window = new TestWindow();
    window.setup_bookmarks();
    Gtk.main();
    return 0;
}
