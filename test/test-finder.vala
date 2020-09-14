using Gtk;

public class TestFinder : Object {
    public static int main(string[] args) {
        Gst.init(ref args);
        Gtk.init(ref args);
        TestFinder tester = new TestFinder();
        Gtk.main();
        return 0;
    }

    Window window;
    Tatam.Finder finder;
    Label footer_label;
    Entry location;
    
    public TestFinder() {
        window = new Window();
        {
            Box box_1 = new Box(Orientation.VERTICAL, 0);
            {
                Box box_2 = new Box(Orientation.HORIZONTAL, 0);
                {
                    Button up_button = new Button.from_icon_name("go-up");
                    {
                        up_button.clicked.connect(() => {
                                File current_dir = File.new_for_path(location.text);
                                finder.change_dir.begin(current_dir.get_parent().get_path());
                            });
                    }

                    Button zoom_in_button = new Button.from_icon_name("zoom-in");
                    {
                        zoom_in_button.clicked.connect(() => {
                                finder.zoom_in();
                            });
                    }

                    Button zoom_out_button = new Button.from_icon_name("zoom-out");
                    {
                        zoom_out_button.clicked.connect(() => {
                                finder.zoom_out();
                            });
                    }
                    
                    location = new Entry();
                    {
                        location.activate.connect(() => {
                                if (GLib.FileUtils.test(location.text, FileTest.IS_DIR)) {
                                    finder.change_dir.begin(location.text);
                                }
                            });
                    }
                    
                    Button find_button = new Button.from_icon_name("folder-open");
                    {
                        find_button.clicked.connect(() => {
                                string? dir_path = Tatam.Dialogs.choose_directory(window);
                                if (dir_path != null) {
                                    location.text = dir_path;
                                    location.activate();
                                }
                            });
                    }
                    
                    box_2.pack_start(up_button, false, false);
                    box_2.pack_start(zoom_in_button, false, false);
                    box_2.pack_start(zoom_out_button, false, false);
                    box_2.pack_start(location, true, true);
                    box_2.pack_start(find_button, false, false);
                }

                ScrolledWindow scrolling = new ScrolledWindow(null, null);
                {
                    finder = Tatam.Finder.create_default_instance();
                    {
                        finder.dir_changed.connect((dir_path) => {
                                footer_label.label = @"Location was changed to $(dir_path)";
                                location.text = dir_path;
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
            window.set_default_size(500, 400);
            window.destroy.connect(Gtk.main_quit);
            window.show_all();
        }

        string css_path = "tatam.css";
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
