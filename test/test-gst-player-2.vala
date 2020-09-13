/*
 * This file is part of tatam.
 * 
 *     tatam is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 * 
 *     tatam is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 * 
 *     You should have received a copy of the GNU General Public License
 *     along with tatam.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright 2020 Takayuki Tanaka
 */

public class TestGstPlayer : TestBase {
    private static Posix.FILE output;
    private Tatam.GstPlayer? gst_player;
    private Gtk.Window window;
    private Gtk.Entry location_entry;
    private Gtk.Button find_button;
    private Tatam.Controller controller;
    private Gtk.TreeStore store;
    private Gtk.TreeView tree_view;

    private bool playing;
    private Tatam.FileInfoAdapter? file_info_reader;
    private Gee.BidirList<Tatam.FileInfo?> playlist;
    private Gee.BidirListIterator<Tatam.FileInfo?> iter;
    
    private string location {
        get {
            return location_entry.text;
        }
        set {
            location_entry.text = value;
            setup_playlist(location_entry.text);
        }
    }
    
    private void construct_window() {
        playing = false;
        window = new Gtk.Window();
        {
            Gtk.Box box_1 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            {
                Gtk.Box box_2 = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                {
                    location_entry = new Gtk.Entry();
                    {
                        location_entry.activate.connect(() => {
                                location = location_entry.text;
                            });
                    }
                    
                    find_button = new Gtk.Button.from_icon_name("document-open-symbolic");
                    {
                        find_button.clicked.connect(() => {
                                print("Call direcotry chooser\n");
                                location_entry.text = Tatam.Dialogs.choose_directory(window);
                                location_entry.activate();
                            });
                    }
                    
                    box_2.pack_start(location_entry, true, true);
                    box_2.pack_start(find_button, false, false);
                }

                controller = new Tatam.Controller();
                {
                    controller.play_button_clicked.connect(() => {
                            debug("controller.play_button_clicked");
                            if (!playing) {
                                gst_player.play(iter.get().path);
                                playing = true;
                            } else {
                                gst_player.unpause();
                            }
                        });
                    controller.pause_button_clicked.connect(() => {
                            debug("controller.pause_button_clicked");
                            gst_player.pause();
                        });
                    controller.next_button_clicked.connect(() => {
                            debug("controller.next_button_clicked");
                            if (iter.has_next()) {
                                iter.next();
                                set_controller_artwork();
                                gst_player.play(iter.get().path);
                            }
                        });
                    controller.prev_button_clicked.connect(() => {
                            debug("controller.prev_button_clicked");
                            if (controller.music_current_time > 1000) {
                                controller.music_current_time = 0;
                                gst_player.quit();
                                gst_player.play(iter.get().path);
                            } else if (iter.has_previous()) {
                                iter.previous();
                                set_controller_artwork();
                                gst_player.play(iter.get().path);
                            }
                        });
                    controller.time_position_changed.connect((new_value) => {
                            debug("controller.time_position_changed");
                            gst_player.set_position(new Tatam.SmallTime.from_milliseconds((uint) new_value));
                        });
                    controller.volume_changed.connect((value) => {
                            debug("controller.volume_changed");
                            gst_player.volume = value;
                        });
                }

                Gtk.Box box_3 = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
                {
                    Gtk.ScrolledWindow playlist_scroll = new Gtk.ScrolledWindow(null, null);
                    {
                        setup_tree_view();
                        playlist_scroll.add(tree_view);
                    }

                    box_3.pack_start(playlist_scroll, true, true);
                }
                
                box_1.pack_start(box_2, false, false);
                box_1.pack_start(controller, false, false);
                box_1.pack_start(box_3, true, true);
            }

            window.add(box_1);
            window.set_default_size(600,10);
            window.destroy.connect(Gtk.main_quit);
            window.show_all();
        }
    }

    private void setup_gst_player() {
        gst_player = new Tatam.GstPlayer();
        gst_player.volume = 0.5;
        gst_player.started.connect(() => {
                debug("gst_player.started was called");
                set_controller_artwork();
                controller.play_pause_button_state = Tatam.Controller.PlayPauseButtonState.PLAY;
            });
        gst_player.error_occured.connect((error) => {
                debug("gst_player.error_occured was called");
                stderr.printf(@"Error: $(error.message)\n");
            });
        gst_player.finished.connect(() => {
                debug("gst_player.finished was called");
                if (iter.has_next()) {
                    debug("playlist has next track");
                    iter.next();
                    gst_player.play(iter.get().path);
                } else {
                    debug("playing all files is completed!");
                    iter = playlist.bidir_list_iterator();
                    iter.next();
                    playing = false;
                }
            });
        gst_player.unpaused.connect(() => {
                print("gst_player.unpaused was called\n");
            });
        gst_player.paused.connect(() => {
                print("gst_player.paused was called\n");
            });
    }

    private void set_controller_artwork() {
        Tatam.FileInfo? info = iter.get();
        if (info == null) {
            return;
        }
        if (info.title != null) {
            controller.music_title = info.title;
        } else {
            controller.music_title = info.name;
        }
        controller.music_total_time = info.time_length.milliseconds;
        controller.activate_buttons(!iter.has_previous(), !iter.has_next());
        if (info.artwork != null) {
            controller.set_artwork(info.artwork);
        }
        print_file_info_pretty(info);
        debug("set_controller_artwork is completed");
    }

    private void setup_file_info_adapter() {
        file_info_reader = new Tatam.FileInfoAdapter();
    }

    private void setup_tree_view() {
        store = new Gtk.TreeStore(6,
                                  typeof(uint),    // track
                                  typeof(string),  // title
                                  typeof(string),  // time
                                  typeof(string),  // artist
                                  typeof(string),  // album
                                  typeof(string)); // genre
        tree_view = new Gtk.TreeView.with_model(store);
        var track_renderer = new Gtk.CellRendererText();
        track_renderer.alignment = Pango.Alignment.RIGHT;
        track_renderer.placeholder_text = "-1";
        var title_renderer = new Gtk.CellRendererText();
        var time_renderer = new Gtk.CellRendererText();
        time_renderer.alignment = Pango.Alignment.RIGHT;
        var artist_renderer = new Gtk.CellRendererText();
        artist_renderer.placeholder_text = "Unknown";
        var album_renderer = new Gtk.CellRendererText();
        album_renderer.placeholder_text = "Unknown";
        var genre_renderer = new Gtk.CellRendererText();
        genre_renderer.placeholder_text = "Unknown";
        var column_track = new Gtk.TreeViewColumn.with_attributes("No.", track_renderer, "text", 0);
        column_track.alignment = (float) 0.5;
        var column_title = new Gtk.TreeViewColumn.with_attributes("Title", title_renderer, "text", 1);
        column_title.expand = true;
        column_title.alignment = (float) 0.5;
        var column_time = new Gtk.TreeViewColumn.with_attributes("Time", time_renderer, "text", 2);
        column_time.alignment = (float) 0.5;
        var column_artist = new Gtk.TreeViewColumn.with_attributes("Artist", artist_renderer, "text", 3);
        column_artist.expand = true;
        column_artist.alignment = (float) 0.5;
        var column_album = new Gtk.TreeViewColumn.with_attributes("Album", album_renderer, "text", 4);
        column_album.expand = true;
        column_album.alignment = (float) 0.5;
        var column_genre = new Gtk.TreeViewColumn.with_attributes("Genre", genre_renderer, "text", 5);
        column_genre.expand = true;
        column_genre.alignment = (float) 0.5;
        tree_view.append_column(column_track);
        tree_view.append_column(column_title);
        tree_view.append_column(column_time);
        tree_view.append_column(column_artist);
        tree_view.append_column(column_album);
        tree_view.append_column(column_genre);
    }
    
    public TestGstPlayer() {
        playing = false;
        construct_window();
        setup_gst_player();
        setup_file_info_adapter();
    }

    private void setup_playlist(string path) {
        try {
            print(@"setup playlist of $(path)\n");
            Gee.List<Tatam.FileInfo?> playlist_local = Tatam.Files.find_file_infos_recursively(path);
            print("playlist was loaded\n");
            if (playlist == null) {
                print("playlist is null then create it.\n");
                playlist = new Gee.ArrayList<Tatam.FileInfo?>();
            }
            playlist.add_all(playlist_local);
            foreach (var info in playlist) {
                print(info.path + "\n");
            }
            print("list is ok\n");
            iter = playlist.bidir_list_iterator();
            iter.next();
            print("iter ok. %d\n", iter.index());
            controller.activate_buttons(!iter.has_previous(), !iter.has_next());

            store.clear();
            foreach (Tatam.FileInfo? item in playlist) {
                Gtk.TreeIter iter;
                store.append(out iter, null);
                store.set(iter,
                          0, item.track, 1, item.title, 2, item.time_length.to_string(),
                          3, item.artist, 4, item.album, 5, item.genre);
            }
        } catch (FileError e) {
            stderr.printf(@"FileError: $(e.message)\n");
        }
    }
    
    public static int main(string[] args) {
        output = Posix.FILE.fdopen(1, "w");
        set_print_handler((text) => output.printf(text));
        Gst.init(ref args);
        Gtk.init(ref args);
        TestGstPlayer tester = new TestGstPlayer();
        Gtk.main();
        return 0;
    }
}
