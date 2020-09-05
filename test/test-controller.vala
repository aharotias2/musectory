class TestWindow : Gtk.Window {
    private Gtk.Button artwork_button;
    private Gtk.Button hide_button;
    private Tatam.Controller con;
    private Gtk.Button activate_button;
    
    public TestWindow() {
        Gtk.Box box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        {
            Gtk.Box button_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            {
                artwork_button = new Gtk.Button.with_label("Push");
                {
                    artwork_button.sensitive = false;
                    artwork_button.clicked.connect(() => {
                            con.show_artwork();
                            artwork_button.sensitive = false;
                        });
                }

                hide_button = new Gtk.Button.with_label("Hide");
                {
                    bool shown = true;
                    hide_button.clicked.connect(() => {
                            if (shown) {
                                con.hide_buttons();
                                shown = false;
                                hide_button.label = "Show";
                            } else {
                                con.show_buttons();
                                shown = true;
                                hide_button.label = "Hide";
                            }
                        });
                }

                activate_button = new Gtk.Button.with_label("Activate");
                {
                    bool active = false;
                    activate_button.clicked.connect(() => {
                            if (active) {
                                con.deactivate_buttons();
                                active = false;
                                activate_button.label = "Activate";
                            } else {
                                con.activate_buttons(false, false);
                                active = true;
                                activate_button.label = "Deactivate";
                            }
                        });
                }
                
                button_box.pack_start(artwork_button);
                button_box.pack_start(hide_button);
                button_box.pack_start(activate_button);
            }
            
            con = new Tatam.Controller();
            {
                con.music_total_time = 1234567;
                
                con.artwork_clicked.connect(() => {
                        artwork_button.sensitive = true;
                        print("artwork clicked!\n");
                    });

                con.play_button_clicked.connect(() => {
                        print("play button was clicked!\n");
                    });

                con.pause_button_clicked.connect(() => {
                        print("pause button was clicked!\n");
                    });

                con.next_button_clicked.connect(() => {
                        print("next_button_clicked\n");
                    });

                con.prev_button_clicked.connect(() => {
                        print("prev_button_clicked\n");
                    });

                con.time_position_changed.connect((value) => {
                        print("time position changed to %f\n", value);
                    });

                con.volume_changed.connect((value) => {
                        print("volume was changed to %f\n", value);
                    });

                con.shuffle_button_toggled.connect((shuffle_on) => {
                        print("shuffle button was toggled to %s\n", shuffle_on ? "ON" : "OFF");
                    });

                con.repeat_button_toggled.connect((repeat_on) => {
                        print("repeat button was toggled to %s\n", repeat_on ? "ON" : "OFF");
                    });
            }

            box.pack_start(button_box, false, false);
            box.pack_start(con, false, false);
        }
        
        this.add(box);
        this.destroy.connect(Gtk.main_quit);
        this.show_all();
    }
}


int main(string[] args) {
    Gtk.init(ref args);
    TestWindow window = new TestWindow();
    Gtk.main();
    return 0;
}
