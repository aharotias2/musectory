using Gtk, Gst;

public class TestFiles {
    public static int main(string[] args) {
        Gtk.init(ref args);
        Gst.init(ref args);

        TestFiles tester= new TestFiles();

        Gtk.main();
        return 0;
    }

    public TestFiles() {
        init_window();
    }

    private Window window;
    private Entry location;
    private Button find_button;
    private Button button_1;
    private Button button_2;
    private Button button_3;
    private Button button_4;
    private Button button_5;
    private Stack stack;
    private TextView text_view;
    private Image image_view;

    private bool thread_running;
    
    private void init_window() {
        thread_running = false;
        
        window = new Window();
        {
            Box box_1 = new Box(Orientation.VERTICAL, 0);
            {
                Box box_2 = new Box(Orientation.HORIZONTAL, 0);
                {
                    location = new Entry();
                    {
                        location.activate.connect(() => {
                                bool is_dir = GLib.FileUtils.test(location.text, FileTest.IS_DIR);
                                button_1.sensitive = is_dir;
                                button_2.sensitive = is_dir;
                                button_3.sensitive = is_dir;
                                button_4.sensitive = is_dir;
                                button_5.sensitive = is_dir;
                            });
                    }
                    
                    find_button = new Button.with_label("Choose");
                    {
                        find_button.clicked.connect(find_button_clicked);
                    }

                    box_2.pack_start(location, true, true);
                    box_2.pack_start(find_button, false, false);
                }
                
                Box box_3 = new Box(Orientation.HORIZONTAL, 0);
                {
                    button_1 = new Button.with_label("find dir file\nnames");
                    {
                        button_1.sensitive = false;
                        button_1.clicked.connect(() => {
                                if (!thread_running) {
                                    button_1_clicked_async.begin();
                                    stack.visible_child_name = "text";
                                }
                            });
                    }
                    
                    button_2 = new Button.with_label("find dir file\ninfo");
                    {
                        button_2.sensitive = false;
                        button_2.clicked.connect(() => {
                                if (!thread_running) {
                                    button_2_clicked_async.begin();
                                    stack.visible_child_name = "text";
                                }
                            });
                    }

                    button_3 = new Button.with_label("find file names\nrecursively");
                    {
                        button_3.sensitive = false;
                        button_3.clicked.connect(() => {
                                if (!thread_running) {
                                    button_3_clicked_async.begin();
                                    stack.visible_child_name = "text";
                                }
                            });
                    }

                    button_4 = new Button.with_label("load first\nartwork");
                    {
                        button_4.sensitive = false;
                        button_4.clicked.connect(() => {
                                if (!thread_running) {
                                    button_4_clicked_async.begin();
                                    stack.visible_child_name = "image";
                                }
                            });
                    }

                    button_5 = new Button.with_label("get file info\nlist in dir");
                    {
                        button_5.sensitive = false;
                        button_5.clicked.connect(() => {
                                if (!thread_running) {
                                    button_5_clicked_async.begin();
                                    stack.visible_child_name = "text";
                                }
                            });
                    }
                    
                    box_3.pack_start(button_1, true, true);
                    box_3.pack_start(button_2, true, true);
                    box_3.pack_start(button_3, true, true);
                    box_3.pack_start(button_4, true, true);
                    box_3.pack_start(button_5, true, true);
                }

                stack = new Stack();
                {
                    ScrolledWindow scrolling_1 = new ScrolledWindow(null, null);
                    {
                        text_view = new TextView();
                        {
                            text_view.editable = false;
                        }
                        
                        scrolling_1.add(text_view);
                    }

                    ScrolledWindow scrolling_2 = new ScrolledWindow(null, null);
                    {
                        image_view = new Image();

                        scrolling_2.add(image_view);
                    }

                    stack.add_named(scrolling_1, "text");
                    stack.add_named(scrolling_2, "image");
                }
                
                box_1.pack_start(box_2, false, false);
                box_1.pack_start(box_3, false, false);
                box_1.pack_start(stack, true, true);
            }

            window.add(box_1);
            window.destroy.connect(Gtk.main_quit);
            window.set_default_size(500, 500);
            window.show_all();
        }
    }

    private void find_button_clicked() {
        string? dir_path = Tatam.Dialogs.choose_directory(window);
        if (dir_path != null) {
            location.text = dir_path;
            location.activate();
        }
    }

    private async void button_1_clicked_async() {
        if (thread_running) {
            return;
        }
        new Thread<int>("button_1_thread", () => {
                Gee.List<string> dir_list;
                Gee.List<string> file_list;
                Tatam.Files.find_dir_file_names(
                    location.text, out dir_list, out file_list
                    );
                StringBuilder sb = new StringBuilder();
                foreach (string dir_path in dir_list) {
                    sb.append(dir_path).append("\n");
                }
                foreach (string file_path in file_list) {
                    sb.append(file_path).append("\n");
                }
                text_view.buffer.text = sb.str;
                stack.visible_child_name = "text";
                Idle.add(button_1_clicked_async.callback);
                return 0;
            });
        thread_running = true;
        yield;
        thread_running = false;
    }

    private async void button_2_clicked_async() {
        if (thread_running) {
            return;
        }
        new Thread<int>("button_2_thread", () => {
                try {
                    Gee.List<string> dir_list;
                    Gee.List<Tatam.FileInfo?> file_list;
                    Tatam.Files.find_dir_files(
                        location.text, out dir_list, out file_list
                        );
                    StringBuilder sb = new StringBuilder();
                    foreach (string dir_path in dir_list) {
                        sb.append(dir_path).append("\n");
                    }
                    foreach (Tatam.FileInfo? file_info in file_list) {
                        sb.append(file_info.path).append("\n");
                    }
                    debug(@"button_2_clicked: $(sb.str)");
                    text_view.buffer.text = sb.str;
                } catch (Tatam.Error e) {
                    text_view.buffer.text = @"Tatam.Error: $(e.message)";
                } catch (GLib.Error e) {
                    text_view.buffer.text = @"GLib.Error: $(e.message)";
                }
                Idle.add(button_2_clicked_async.callback);
                return 0;
            });
        thread_running = true;
        yield;
        thread_running = false;
    }

    private async void button_3_clicked_async() {
        if (thread_running) {
            return;
        }
        new Thread<int>("button_3_thread", () => {
                Gee.List<string> file_list = Tatam.Files.find_file_names_recursively(location.text);
                StringBuilder sb = new StringBuilder();
                foreach (string file_path in file_list) {
                    debug(@"button_3_clicked: $(file_path)");
                }
                debug("button_3_clicked: list finished");
                foreach (string file_path in file_list) {
                    sb.append(file_path).append("\n");
                }
                debug("button_3_clicked: text = " + sb.str);
                text_view.buffer.text = sb.str;
                Idle.add(button_3_clicked_async.callback);
                return 0;
            });
        thread_running = true;
        yield;
        thread_running = false;
    }

    private async void button_4_clicked_async() {
        if (thread_running) {
            return;
        }
        new Thread<int>("button_4_thread", () => {
                try {
                    Gdk.Pixbuf? pixbuf = Tatam.Files.load_first_artwork(location.text, 500);
                    if (pixbuf != null) {
                        image_view.pixbuf = pixbuf;
                    }
                } catch (GLib.FileError e) {
                    text_view.buffer.text = @"FileError: $(e.message)";
                } catch (Tatam.Error e) {
                    text_view.buffer.text = @"Tatam.Error: $(e.message)";
                }
                Idle.add(button_4_clicked_async.callback);
                return 0;
            });
        thread_running = true;
        yield;
        thread_running = false;
    }

    private async void button_5_clicked_async() {
        if (thread_running) {
            return;
        }
        new Thread<int>("button_5_thread", () => {
                try {
                    Gee.List<Tatam.FileInfo?> list;
                    list = Tatam.Files.get_file_info_list_in_dir(location.text);
                    if (list != null && list.size > 0) {
                        StringBuilder sb = new StringBuilder("[");
                        for (int i = 0; i < list.size; i++) {
                            sb.append(list.get(i).to_string());
                            if (i < list.size - 1) {
                                sb.append(", ");
                            }
                        }
                        sb.append("]");
                        debug(@"button_5_clicked: $(sb.str)");
                        Json.Node json = Json.from_string(sb.str);
                        string pretty_json = Json.to_string(json, true);
                        text_view.buffer.text = pretty_json.dup();
                        stack.visible_child_name = "text";
                    }
                } catch (Tatam.Error e) {
                    text_view.buffer.text = @"Tatam.Error: $(e.message)";
                } catch (GLib.Error e) {
                    text_view.buffer.text = @"GLib.Error: $(e.message)";
                }
                Idle.add(button_5_clicked_async.callback);
                return 0;
            });
        thread_running = true;
        yield;
        thread_running = false;
    }        
}
