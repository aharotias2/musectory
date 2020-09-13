using Gtk;

public class TestFinder : Object {
    public static int main(string[] args) {
        Gtk.init(ref args);
        TestFinder tester = new TestFinder();
        Gtk.main();
        return 0;
    }

    Window window;
    Tatam.Finder finder;
    Label footer_label;
    
    public TestFinder() {
        window = new Window();
        {
            Box box_1 = new Box(Orientation.VERTICAL, 0);
            {
                Box box_2 = new Box(Orientation.HORIZONTAL, 0);
                {
                    Entry location = new Entry();

                    Button find_button = new Button.from_icon_name("file-open-symbolic");
                    {
                        find_button.clicked.connect(() => {
                                string? dir_path = Tatam.Dialogs.choose_directory(window);
                                if (dir_path != null) {
                                    location.text = dir_path;
                                    finder.change_dir.begin(dir_path);
                                }
                            });
                    }
                    
                    box_2.pack_start(location, true, true);
                    box_2.pack_start(find_button, false, false);
                }

                ScrolledWindow scrolling = new ScrolledWindow(null, null);
                {
                    finder = Tatam.Finder.create_default_instance();
                    {
                        finder.dir_changed.connect((dir_path) => {
                                footer_label.label = @"Location was changed to $(dir_path)";
                            });

                        finder.bookmark_button_clicked.connect((file_path) => {
                                footer_label.label = @"Bookmark button was clicked at $(file_path)";
                            });

                        finder.add_button_clicked.connect((file_path) => {
                                footer_label.label = @"Add button was clicked at $(file_path)";
                            });

                        finder.play_button_clicked.connect((file_path) => {
                                footer_label.label = @"Play button was clicked at $(file_path)";
                            });

                        finder.icon_image_resized.connect((icon_size) => {
                                footer_label.label = @"Icon size was changed to $(icon_size)";
                            });

                        finder.file_button_clicked.connect((file_path) => {
                                footer_label.label = @"File button was clicked at $(file_path)";
                                finder.change_dir.begin(file_path);
                            });
                    }

                    scrolling.add(finder);
                }

                footer_label = new Label("");
                
                box_1.pack_start(box_2, false, false);
                box_1.pack_start(scrolling, true, true);
                box_1.pack_start(footer_label, false, false);
            }

            window.add(box_1);
            window.destroy.connect(Gtk.main_quit);
            window.show_all();
        }

        string css_path = "main.css";
        if (GLib.FileUtils.test(css_path, FileTest.EXISTS)) {
            Gdk.Screen win_screen = window.get_screen();
            CssProvider css_provider = new CssProvider();
            try {
                css_provider.load_from_path(css_path);
                Gtk.StyleContext.add_provider_for_screen(win_screen,
                                                         css_provider,
                                                         Gtk.STYLE_PROVIDER_PRIORITY_USER);
            } catch (Error e) {
                debug("ERROR: css_path: %s", css_path);
                stderr.printf(Tatam.Text.ERROR_CREATE_WINDOW);
            }
        }
    }
}