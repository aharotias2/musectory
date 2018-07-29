/*
 * This file is part of dplayer.
 * 
 *     dplayer is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 * 
 *     dplayer is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 * 
 *     You should have received a copy of the GNU General Public License
 *     along with dplayer.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright 2018 Takayuki Tanaka
 */

using Gtk, DPlayer;

//--------------------------------------------------------------------------------------
// Delegates
//--------------------------------------------------------------------------------------
delegate void TimeLabelSetFunc(double seconds);

//--------------------------------------------------------------------------------------
// Constants
//--------------------------------------------------------------------------------------
const string program_name = "dplayer";

//--------------------------------------------------------------------------------------
// ファイル リスト系のグローバル変数
//--------------------------------------------------------------------------------------
List<string> dirs;
CompareFunc<string> string_compare_func;
CopyFunc<DFileInfo?> file_info_copy_func;
string current_dir = null;

//--------------------------------------------------------------------------------------
// 楽曲再生用のグローバル変数
//--------------------------------------------------------------------------------------
Music music;

string music_total_time;
double music_total_time_seconds;
double music_time_position;
Gdk.Pixbuf current_playing_artwork;

//--------------------------------------------------------------------------------------
// 画像系のグローバル変数
//--------------------------------------------------------------------------------------
Gdk.Pixbuf cd_pixbuf;
Gdk.Pixbuf folder_pixbuf;
Gdk.Pixbuf file_pixbuf;
Gdk.Pixbuf parent_pixbuf;
Image view_list_image;
Image view_grid_image;
int max_width;
int max_height;
int artwork_max_size;

//--------------------------------------------------------------------------------------
// GUIウィジェット用のグローバル変数
//--------------------------------------------------------------------------------------
Window main_win;
HeaderBar? win_header;
DPlayerStack stack;
Button artwork_button;
Image artwork;
Box controller;
Overlay music_view_overlay;
Button header_sidebar_button;
Image music_view_artwork;
Label music_title;
ProgressBar time_bar;
Label time_label_current;
Label time_label_rest;
ToolButton play_pause_button;
ToolButton next_track_button;
ToolButton prev_track_button;
ToggleButton toggle_shuffle_button;
ToggleButton toggle_repeat_button;
DPlayer.Finder finder;
TreeView bookmark_tree;
DPlayer.PlaylistBox playlist;
ScrolledWindow music_view_container;
Label playlist_view_dir_label;
TimeLabelSetFunc time_label_set;
int saved_main_win_width;
int saved_main_win_height;
int window_default_width = 900;
int window_default_height = 750;

Dialog help_dialog;
Dialog config_dialog;

const Gdk.RGBA music_view_bg_color = {0.1, 0.1, 0.1, 1.0};
const Gdk.RGBA music_view_close_button_bg_color = {0.8, 0.8, 0.8, 0.4};

const string[] icon_dirs = {"/usr/share/icons/hicolor/48x48/apps/",
                            "/usr/local/share/icons/hicolor/48x48/apps/",
                            "~/.icons"};


//--------------------------------------------------------------------------------------
// その他の設定系のグローバル変数
//--------------------------------------------------------------------------------------
bool print_message_of_send_mplayer_command;
DPlayerOptions options;

//--------------------------------------------------------------------------------------
// 小道具関数
//--------------------------------------------------------------------------------------
Gdk.Pixbuf? get_application_icon_at_size(uint width, uint height) {
    try {
        foreach (string dir in icon_dirs) {
            if (dir.index_of_char('~') == 0) {
                dir = dir.replace("~", Environment.get_home_dir());
            }
            string icon_name = dir + "/" + program_name + ".png";
            debug("icon path : " + icon_name);
            if (FileUtils.test(icon_name, FileTest.EXISTS)) {
                return new Gdk.Pixbuf.from_file_at_size(icon_name, 64, 64);
            }
        }
        return null;
    } catch (Error e) {
        return null;
    }
}

//--------------------------------------------------------------------------------------
// アプリケーション処理
//--------------------------------------------------------------------------------------

void application_quit() {
    if (music.playing) {
        music.quit();
    }

    Timeout.add(1, () => {
            if (!music.playing) {
                Gtk.main_quit();
                return Source.REMOVE;
            } else {
                return Source.CONTINUE;
            }
        });
}

void show_about_dialog(Window main_win) {
    if (help_dialog == null) {
        help_dialog = new Dialog.with_buttons(program_name + " info",
                                              main_win,
                                              DialogFlags.MODAL | DialogFlags.DESTROY_WITH_PARENT,
                                              "_OK",
                                              ResponseType.NONE);
        {
            var help_dialog_vbox = new Box(Orientation.VERTICAL, 0);
            {
                var help_dialog_label_text = new Label("<span size=\"24000\"><b>" + program_name + "</b></span>");
                help_dialog_label_text.use_markup = true;
                help_dialog_label_text.margin = 10;

                help_dialog_vbox.pack_start(new Image.from_pixbuf(get_application_icon_at_size(64, 64)));
                help_dialog_vbox.pack_start(help_dialog_label_text, false, false);
                help_dialog_vbox.pack_start(new Label("フォルダで音楽を管理する人のためのプレイヤ"), false, false);
                help_dialog_vbox.pack_start(new Label("Ⓒ 2017 Tanaka Takayuki"), false, false);
                help_dialog_vbox.margin = 20;
            }
            help_dialog.get_content_area().add(help_dialog_vbox);
            help_dialog.response.connect(() => {
                    help_dialog.visible = false;
                });
            help_dialog.destroy.connect(() => {
                    help_dialog = null;
                });
            help_dialog.show_all();
        }
    }
    help_dialog.visible = true;
}

void show_config_dialog(Window main_win) {
    if (config_dialog == null) {
        // 設定ダイアログ本体
        string _ao_type = options.ao_type;
        bool _use_csd = options.use_csd;
        RadioButton *p_radio_audio_alsa;
        RadioButton *p_radio_audio_pulse;
        RadioButton *p_radio_use_csd_yes;
        RadioButton *p_radio_use_csd_no;
        SpinButton *p_spin_thumbnail_size;
        SpinButton *p_spin_playlist_image_size;

        config_dialog = new Dialog.with_buttons(program_name + " settings",
                                                main_win,
                                                DialogFlags.MODAL | DialogFlags.DESTROY_WITH_PARENT,
                                                "_OK",
                                                ResponseType.ACCEPT,
                                                "_Cancel",
                                                ResponseType.CANCEL);
        {
            var config_dialog_vbox = new Box(Orientation.VERTICAL, 5);
            {
                // ALSAかPulseAudioかの選択
                var frame_audio_choice = new Frame("Select the sound system");
                {
                    var frame_audio_choice_vbox = new Box(Orientation.VERTICAL, 0);
                    {
                        var radio_audio_alsa = new RadioButton.with_label(null, "ALSA");
                        {
                            if (options.ao_type == "alsa") {
                                radio_audio_alsa.active = true;
                            }
                            radio_audio_alsa.toggled.connect(() => {
                                    _ao_type = radio_audio_alsa.active ? "alsa" : "pulse";
                                });
                            p_radio_audio_alsa = radio_audio_alsa;
                        }

                        var radio_audio_pulse = new RadioButton.with_label_from_widget(radio_audio_alsa, "PulseAudio");
                        {
                            if (options.ao_type == "pulse") {
                                radio_audio_pulse.active = true;
                            }
                            radio_audio_pulse.toggled.connect(() => {
                                    _ao_type = radio_audio_pulse.active ? "pulse" : "alsa";
                                });
                            p_radio_audio_pulse = radio_audio_pulse;
                        }

                        frame_audio_choice_vbox.margin = 5;
                        frame_audio_choice_vbox.pack_start(radio_audio_alsa);
                        frame_audio_choice_vbox.pack_start(radio_audio_pulse);
                    }

                    frame_audio_choice.add(frame_audio_choice_vbox);
                }

                // サムネイルサイズの選択
                var frame_thumbnail_size = new Frame("the size of thumbnails");
                {
                    var spin_thumbnail_size = new SpinButton.with_range(1, 500, 1);
                    {
                        spin_thumbnail_size.margin = 5;
                        spin_thumbnail_size.numeric = false;
                        spin_thumbnail_size.value = options.thumbnail_size;
                        p_spin_thumbnail_size = spin_thumbnail_size;
                    }

                    frame_thumbnail_size.add(spin_thumbnail_size);
                }

                // プレイリスト画像サイズの選択
                var frame_playlist_image_size = new Frame("the size of playlist's image");
                {
                    var spin_playlist_image_size = new SpinButton.with_range(1, 500, 1);
                    {
                        spin_playlist_image_size.margin = 5;
                        spin_playlist_image_size.numeric = false;
                        spin_playlist_image_size.value = options.playlist_image_size;
                        p_spin_playlist_image_size = spin_playlist_image_size;
                    }

                    frame_playlist_image_size.add(spin_playlist_image_size);
                }

                // Client Side Decorationを使うかどうかの選択
                var frame_use_csd = new Frame("Use CSD?");
                {
                    var frame_use_csd_box = new Box(Orientation.HORIZONTAL, 0);
                    {
                        var radio_use_csd_yes = new RadioButton.with_label(null, "Yes");
                        {
                            if (options.use_csd) {
                                radio_use_csd_yes.active = true;
                            }
                            radio_use_csd_yes.toggled.connect(() => {
                                    _use_csd = true;
                                });
                            p_radio_use_csd_yes = radio_use_csd_yes;
                        }

                        var radio_use_csd_no = new RadioButton.with_label_from_widget(radio_use_csd_yes, "No");
                        {
                            if (!options.use_csd) {
                                radio_use_csd_no.active = true;
                            }
                            radio_use_csd_no.toggled.connect(() => {
                                    _use_csd = false;
                                });
                            p_radio_use_csd_no = radio_use_csd_no;
                        }

                        frame_use_csd_box.pack_start(radio_use_csd_yes);
                        frame_use_csd_box.pack_start(radio_use_csd_no);
                    }
                    frame_use_csd.add(frame_use_csd_box);
                }

                config_dialog_vbox.margin = 5;
                config_dialog_vbox.pack_start(frame_audio_choice);
                config_dialog_vbox.pack_start(frame_thumbnail_size);
                config_dialog_vbox.pack_start(frame_playlist_image_size);
                config_dialog_vbox.pack_start(frame_use_csd);
            }

            config_dialog.get_content_area().add(config_dialog_vbox);

            config_dialog.response.connect((response_id) => {
                    switch (response_id) {
                    case ResponseType.ACCEPT:
                        options.ao_type = _ao_type;
                        options.thumbnail_size = (int)p_spin_thumbnail_size->value;
                        options.playlist_image_size = (int)p_spin_playlist_image_size->value;
                        if (artwork.pixbuf != null) {
                            artwork.pixbuf = MyUtils.PixbufUtils.scale_limited(current_playing_artwork,
                                                                               options.thumbnail_size);
                        }

                        debug("_use_csd: " + (_use_csd ? "true" : "false"));
                        debug("options.use_csd: " + (options.use_csd ? "true" : "false"));
                        if (options.use_csd != _use_csd) {
                            options.use_csd = _use_csd;
                        }

                        break;

                    case ResponseType.CANCEL:
                        switch (options.ao_type) {
                        case "alsa":
                            p_radio_audio_alsa->active = true;
                            break;

                        case "pulse":
                            p_radio_audio_pulse->active = true;
                            break;
                        }
                                    
                        if (options.use_csd) {
                            p_radio_use_csd_yes->active = true;
                        } else {
                            p_radio_use_csd_no->active = true;
                        }

                        break;
                    }
                    config_dialog.visible = false;
                });

            config_dialog.destroy.connect(() => {
                    config_dialog = null;
                });

            config_dialog.show_all();
        }
    } else {
        config_dialog.visible = true;
    }
}


//--------------------------------------------------------------------------------------
// メイン関数
//--------------------------------------------------------------------------------------
int main(string[] args) {
    //----------------------------------------------------------------------------------
    // mplayerコマンドの存在確認
    //----------------------------------------------------------------------------------
    if (Posix.system("mplayer") != 0) {
        stderr.printf("mplayer command does not exist.\n");
        Process.exit(1);
    }

    //----------------------------------------------------------------------------------
    // グローバル変数の初期化
    //----------------------------------------------------------------------------------
    dirs = new List<string>();

    file_info_copy_func = (a) => {
        DFileInfo b = new DFileInfo();
        b.dir = a.dir;
        b.name = a.name;
        b.path = a.path;
        b.album = a.album;
        b.artist = a.artist;
        b.comment = a.comment;
        b.genre = a.genre;
        b.title = a.title;
        b.track = a.track;
        b.disc = a.disc;
        b.date = a.date;
        b.time_length = a.time_length;
        b.artwork = a.artwork;
        return b;
    };

    string_compare_func = (a, b) => {
        return a.collate(b);
    };

    print_message_of_send_mplayer_command = true;

    //----------------------------------------------------------------------------------
    // 設定ファイルの読み込み
    //----------------------------------------------------------------------------------
    string config_file_path = Environment.get_home_dir() + "/." + program_name;
    string config_file_contents;

    options.ao_type = "pulse";
    options.use_csd = true;
    options.thumbnail_size = 80;
    options.show_thumbs_at = ShowThumbsAt.ALBUMS;
    options.playlist_image_size = 64;
    
    current_dir = null;

    try {
        if (FileUtils.test(config_file_path, FileTest.EXISTS)) {
            FileUtils.get_contents(config_file_path, out config_file_contents);

            string[] config_file_lines = config_file_contents.split("\n", -1);

            foreach (string line in config_file_lines) {
                string[] pair = line.split("=", 2);
                switch (pair[0]) {
                case "dir":
                    dirs.append(pair[1]);
                    break;

                case "ao_type":
                    options.ao_type = pair[1];
                    break;

                case "thumbnail_size":
                    options.thumbnail_size = int.parse(pair[1]);
                    break;

                case "use_csd":
                    if (pair[1] == "true") {
                        options.use_csd = true;
                    } else if (pair[1] == "false") {
                        options.use_csd = false;
                    }
                    break;

                case "cwd":
                    current_dir = pair[1];
                    break;

                case "playlist_image_size":
                    options.playlist_image_size = int.parse(pair[1]);
                    break;
                }
            }
        }

        if (dirs.length() == 0) {
            dirs.append(Environment.get_home_dir() + "/Music");
        }
    } catch(Error e) {
        dirs.append(Environment.get_home_dir() + "/home/ta/Music");
    }

    //----------------------------------------------------------------------------------
    // コマンドラインオプションの読み込み
    //----------------------------------------------------------------------------------
    for (int i = 1; i < args.length; i++) {
        switch (args[i]) {
        case "-a":
            i++;
            if (args[i] != "alsa" && args[i] != "pulse") {
                Process.exit(1);
            }

            options.ao_type = args[i];
            break;

        default:
            stderr.printf(program_name + ": Unknown command line options \"" + args[i] + "\"");
            Process.exit(1);
        }
    }

    //----------------------------------------------------------------------------------
    // 一時ファイル用のディレクトリを作成
    //----------------------------------------------------------------------------------
    File tmp_dir = File.new_for_path("/tmp/" + program_name);
    if (!FileUtils.test("/tmp/" + program_name, FileTest.EXISTS)) {
        try {
            tmp_dir.make_directory();
        } catch(Error e) {
            stderr.printf("making a tmp directory was failed.\n");
            Process.exit(1);
        }
    }

    //----------------------------------------------------------------------------------
    // CSSファイルの場所を設定
    //----------------------------------------------------------------------------------
    string home_dir = Environment.get_variable("HOME");
    debug("home_dir = %s", home_dir);
    string css_path = home_dir + "/.config/dplayer.css";
    
    Gtk.init(ref args);

    //----------------------------------------------------------------------------------
    // ローカル変数の設定
    //----------------------------------------------------------------------------------

    TreeIter bookmark_root;
    Revealer *p_bookmark_revealer = null;
    Revealer *p_back_button_revealer = null;
    Button *p_music_view_close_button = null;
    Button *p_finder_next_button = null;
    
    TreeViewColumn *p_bookmark_title_col = null;

    var screen = Gdk.Screen.get_default();

    debug("get screen: " + (screen != null ? "ok." : "failed"));
    
    max_width = screen.get_width();
    max_height = screen.get_height();

    debug("Max width of the display: " + max_width.to_string());
    debug("Max height of the display: " + max_height.to_string());

    window_default_height = (int) (max_height * 0.7);
    window_default_width = int.min((int) (max_width * 0.5), (int) (window_default_height * 1.3));
    
    artwork_max_size = int.min(max_width, max_height);

    //----------------------------------------------------------------------------------
    // アイコン画像の読み込み
    //----------------------------------------------------------------------------------

    IconTheme icon_theme = Gtk.IconTheme.get_default();
    try {
        file_pixbuf = icon_theme.load_icon("audio-x-generic", 64, 0);
        cd_pixbuf = icon_theme.load_icon("media-optical", 64, 0);
        folder_pixbuf = icon_theme.load_icon("folder-music", 64, 0);
        if (folder_pixbuf == null) {
            folder_pixbuf = icon_theme.load_icon("folder", 64, 0);
        }
        parent_pixbuf = icon_theme.load_icon("go-up", 64, 0);
        view_list_image = new Image.from_icon_name("view-list-symbolic", IconSize.BUTTON);
        view_grid_image = new Image.from_icon_name("view-grid-symbolic", IconSize.BUTTON);
    } catch (Error e) {
        stderr.printf("icon file can not load.\n");
        Process.exit(1);
    }

    //----------------------------------------------------------------------------------
    // ウィンドウヘッダの作成
    //----------------------------------------------------------------------------------

    win_header = null;
 
    if (options.use_csd) {
        win_header = new HeaderBar();
        {
            var header_box = new Box(Orientation.HORIZONTAL, 0);
            {
                header_sidebar_button = new Button();
                {
                    header_sidebar_button.get_style_context().add_class("titlebutton");
                    header_sidebar_button.add(new Image.from_icon_name("view-list-symbolic", IconSize.BUTTON));
                    header_sidebar_button.clicked.connect(() => {
                            if (stack.is_finder_visible()) {
                                //hoge
                                DFileInfo file_info = playlist.track_data();

                                if (options.use_csd) {
                                    if (file_info.title != null) {
                                        win_header.set_title(file_info.title);
                                    } else {
                                        win_header.set_title(file_info.name);
                                    }
                                } else {
                                    if (file_info.title != null) {
                                        playlist_view_dir_label.label = "<b><i>" + file_info.title + "</i></b>";
                                    } else {
                                        playlist_view_dir_label.label = "<b><i>" + file_info.name + "</i></b>";
                                    }
                                }
                                if (current_playing_artwork != null) {
                                    artwork_button.visible = true;
                                }
                                music_view_artwork.visible = false;
                                stack.show_playlist();
                                header_sidebar_button.image = view_grid_image;
                            } else if (stack.is_playlist_visible()) {
                                if (options.use_csd) {
                                    win_header.set_title(finder.dir_path);
                                } else {
                                    main_win.title = finder.dir_path;
                                }
                                if (current_playing_artwork != null) {
                                    artwork_button.visible = true;
                                }
                                music_view_artwork.visible = false;
                                stack.show_finder();
                                header_sidebar_button.image = view_list_image;
                            }
                        });
                }

#if PREPROCESSOR_DEBUG
                var debug_print_music_button = new Button.with_label("d1");
                {
                    debug_print_music_button.get_style_context().add_class("title_button");
                    debug_print_music_button.clicked.connect(() => {
                            music.debug_print_current_playlist();
                        });
                }
#endif

                header_box.add(header_sidebar_button);

#if PREPROCESSOR_DEBUG
                // debug
                header_box.add(debug_print_music_button);
#endif
            }

            var header_menu_button = new Gtk.MenuButton();
            {
                var header_menu = new Gtk.Menu();
                {
                    var menu_item_config = new Gtk.ImageMenuItem.with_label("Config...");
                    {
                        menu_item_config.always_show_image = true;
                        menu_item_config.image = new Image.from_icon_name("emblem-system-symbolic", IconSize.SMALL_TOOLBAR);
                        menu_item_config.activate.connect(() => {
                                show_config_dialog(main_win);
                            });
                    }

                    var menu_item_about = new Gtk.ImageMenuItem.with_label("About...");
                    {
                        menu_item_about.always_show_image = true;
                        menu_item_about.image = new Image.from_icon_name("help-faq-symbolic", IconSize.SMALL_TOOLBAR);
                        menu_item_about.activate.connect(() => {
                                show_about_dialog(main_win);
                            });
                    }

                    var menu_item_quit = new ImageMenuItem.with_label("Close");
                    {
                        menu_item_quit.always_show_image = true;
                        menu_item_quit.image = new Image.from_icon_name("application-exit-symbolic", IconSize.SMALL_TOOLBAR);
                        menu_item_quit.activate.connect(() => {
                                if (music.playing) {
                                    music.quit();
                                }
                                Gtk.main_quit();
                            });
                    }

                    header_menu.add(menu_item_config);
                    header_menu.add(menu_item_about);
                    header_menu.add(new SeparatorMenuItem());
                    header_menu.add(menu_item_quit);
                    header_menu.show_all();
                }

                header_menu_button.image = new Image.from_icon_name("open-menu-symbolic", IconSize.BUTTON);
                header_menu_button.get_style_context().add_class("titlebutton");
                header_menu_button.direction = ArrowType.DOWN;
                header_menu.halign = Align.END;
                header_menu_button.popup = header_menu;
                header_menu_button.use_popover = false;
            }

            var header_fold_button = new Button();
            {
                header_fold_button.get_style_context().add_class("titlebutton");
                header_fold_button.add(new Image.from_icon_name("go-up-symbolic", IconSize.BUTTON));
                header_fold_button.sensitive = true;
                header_fold_button.clicked.connect(() => {
                        if (stack.is_visible()) {
                            saved_main_win_width = main_win.get_allocated_width();
                            saved_main_win_height = main_win.get_allocated_height();
                            main_win.resize(saved_main_win_width, 1);
                            header_fold_button.image = new Image.from_icon_name("go-down-symbolic", IconSize.BUTTON);
                            stack.hide();
                            prev_track_button.visible = false;
                            next_track_button.visible = false;
                            toggle_repeat_button.visible = false;
                            toggle_shuffle_button.visible = false;
                            header_sidebar_button.sensitive = false;
                            artwork_button.sensitive = false;
                        } else {
                            main_win.resize(main_win.get_allocated_width(), saved_main_win_height);
                            header_fold_button.image = new Image.from_icon_name("go-up-symbolic", IconSize.BUTTON);
                            stack.show();
                            prev_track_button.visible = true;
                            next_track_button.visible = true;
                            toggle_repeat_button.visible = true;
                            toggle_shuffle_button.visible = true;
                            header_sidebar_button.sensitive = true;
                            artwork_button.sensitive = true;
                        }
                    });

            }

            win_header.show_close_button = false;
            win_header.title = program_name;
            win_header.has_subtitle = false;
            win_header.pack_start(header_box);
            win_header.pack_end(header_menu_button);
            win_header.pack_end(header_fold_button);
        }
    }

    //----------------------------------------------------------------------------------
    // 操作パネルの作成
    //----------------------------------------------------------------------------------
    controller = new Box(Orientation.HORIZONTAL, 2);
    {
        artwork_button = new Button();
        {
            artwork = new Image();
            {
                artwork.margin = 0;
            }

            artwork_button.margin = 0;
            artwork_button.relief = ReliefStyle.NORMAL;
            artwork_button.get_style_context().add_class("flat");
            artwork_button.add(artwork);
            artwork_button.clicked.connect(() => {
                    if (options.use_csd) {
                        win_header.set_title(music_title.label);
                    } else {
                        main_win.title = music_title.label;
                    }
                    artwork_button.visible = false;
                    music_view_overlay.visible = true;

                    Timeout.add(80, () => {
                            debug("enter timeout artwork_button.clicked");
                            int size = int.min(music_view_container.get_allocated_width(),
                                               music_view_container.get_allocated_height());
                            music_view_artwork.pixbuf = MyUtils.PixbufUtils.scale_limited(current_playing_artwork, size);
                            music_view_artwork.visible = true;
                            header_sidebar_button.sensitive = false;
                            return Source.REMOVE;
                        });
                });
        }

        var controller_second_box = new Box(Orientation.HORIZONTAL, 2);
        {
            play_pause_button = new ToolButton(new Image.from_icon_name("media-playback-start-symbolic",
                                                                        IconSize.SMALL_TOOLBAR), null);
            {
                play_pause_button.sensitive = false;
                play_pause_button.clicked.connect(() => {
                        if (music.playing) {
                            debug("play-pause button was clicked. music is playing. pause it.");
                            music.pause();
                            playlist.toggle_status();
                            if (music.paused) {
                                ((Gtk.Image)play_pause_button.icon_widget).icon_name = "media-playback-start-symbolic";
                            } else {
                                ((Gtk.Image)play_pause_button.icon_widget).icon_name = "media-playback-pause-symbolic";
                            }
                        } else {
                            finder.change_cursor(Gdk.CursorType.WATCH);
                            Timeout.add(1, () => {
                                    debug("play-pause button was clicked. music is not playing. start it.");
                                    if (stack.is_finder_visible()) {
                                        playlist.new_list_from_path(finder.dir_path);
                                        p_finder_next_button->visible = true;
                                    }
                                    stack.show_playlist();
                                    header_sidebar_button.sensitive = true;
                                    header_sidebar_button.image = view_grid_image;
                                    var file_path_list = playlist.get_file_path_list();
                                    music.start(ref file_path_list, options.ao_type);
                                    finder.change_cursor(Gdk.CursorType.LEFT_PTR);
                                    return Source.REMOVE;
                                });
                        }
                    });
            }

            next_track_button = new ToolButton(new Image.from_icon_name("media-skip-forward-symbolic",
                                                                        IconSize.SMALL_TOOLBAR), null);
            {
                next_track_button.sensitive = false;
                next_track_button.clicked.connect(() => {
                        music.play_next();
                        playlist.move_to_next_track();
                    });
            }

            prev_track_button = new ToolButton(new Image.from_icon_name("media-skip-backward-symbolic",
                                                                        IconSize.SMALL_TOOLBAR), null);
            {
                prev_track_button.sensitive = false;
                prev_track_button.clicked.connect(() => {
                        if (music.playing) {
                            debug("prev playlist.track button was clicked. current time position is %.1f in seconds.",
                                  music_time_position);
                            if (playlist.get_track() == 0 || music_time_position > 1.0) {
                                music.move_pos(0);
                                music_time_position = 0;
                                time_bar.fraction = 0;
                                time_label_set(0);
                            } else {
                                music.play_prev();
                            }
                        }
                    });
            }

            controller_second_box.valign = Align.CENTER;
            controller_second_box.vexpand = false;
            controller_second_box.margin_right = 10;
            controller_second_box.get_style_context().add_class("linked");
            controller_second_box.pack_start(prev_track_button, false, false);
            controller_second_box.pack_start(play_pause_button, false, false);
            controller_second_box.pack_start(next_track_button, false, false);
        }

        var time_bar_box = new Box(Orientation.VERTICAL, 2);
        {
            music_title = new Label("");
            {
                music_title.justify = Justification.LEFT;
                music_title.single_line_mode = false;
                music_title.lines = 4;
                music_title.wrap = true;
                music_title.wrap_mode = Pango.WrapMode.WORD_CHAR;
                music_title.ellipsize = Pango.EllipsizeMode.END;
                music_title.margin_start = 5;
                music_title.margin_end = 5;
            }

            time_bar = new ProgressBar();
            {
                time_bar.set_size_request(-1, 12);
                time_bar.show_text = false;
            }

            var time_label_box = new Box(Orientation.HORIZONTAL, 0);
            {
                time_label_current = new Label("0:00:00");
                {
                    time_label_current.get_style_context().add_class("time_label_current");
                }
                time_label_rest = new Label("0:00:00");
                {
                    time_label_rest.get_style_context().add_class("time_label_rest");
                }
                time_label_box.pack_start(time_label_current, false, false);
                time_label_box.pack_end(time_label_rest, false, false);
            }
            
            time_bar_box.valign = Align.CENTER;
            time_bar_box.pack_start(music_title, false, false);
            time_bar_box.pack_start(time_bar, true, false);
            time_bar_box.pack_start(time_label_box, true, false);
        }

        var controller_third_box = new Box(Orientation.HORIZONTAL, 2);
        {
            var volume_button = new ToolButton(
                new Image.from_icon_name("audio-volume-medium-symbolic", IconSize.SMALL_TOOLBAR), null);
            {
                var popover = new Popover(volume_button);
                {
                    var volume_bar = new Scale.with_range(Orientation.VERTICAL, 0, 100, -1);
                    {
                        volume_bar.set_value(50);
                        volume_bar.has_origin = true;
                        volume_bar.set_inverted(true);
                        volume_bar.draw_value = true;
                        volume_bar.value_pos = PositionType.BOTTOM;
                        volume_bar.margin = 5;
                        volume_bar.value_changed.connect(() => {
                                if (music.playing) {
                                    music.set_volume(volume_bar.get_value());
                                }
                                if (volume_bar.get_value() == 0) {
                                    ((Gtk.Image) volume_button.icon_widget).icon_name = "audio-volume-muted-symbolic";
                                } else if (volume_bar.get_value() < 35) {
                                    ((Gtk.Image) volume_button.icon_widget).icon_name = "audio-volume-low-symbolic";
                                } else if (volume_bar.get_value() < 75) {
                                    ((Gtk.Image) volume_button.icon_widget).icon_name = "audio-volume-medium-symbolic";
                                } else {
                                    ((Gtk.Image) volume_button.icon_widget).icon_name = "audio-volume-high-symbolic";
                                }
                            });

                    }

                    popover.add(volume_bar);
                    popover.modal = true;
                    popover.position = PositionType.TOP;
                    popover.set_size_request(20, 150);
                    volume_bar.show();
                }

                volume_button.clicked.connect(() => {popover.visible = !popover.visible;});
            }

            toggle_shuffle_button = new ToggleButton();
            {
                toggle_shuffle_button.image = new Image.from_icon_name("media-playlist-shuffle-symbolic",
                                                                       IconSize.SMALL_TOOLBAR);
                toggle_shuffle_button.active = false;
                toggle_shuffle_button.draw_indicator = false;
                toggle_shuffle_button.valign = Align.CENTER;
                toggle_shuffle_button.halign = Align.CENTER;
                toggle_shuffle_button.toggled.connect(() => {
                        playlist.toggle_shuffle();
                        music.toggle_shuffle();
                    });
            }

            toggle_repeat_button = new ToggleButton();
            {
                toggle_repeat_button.image = new Image.from_icon_name("media-playlist-repeat-symbolic",
                                                                      IconSize.SMALL_TOOLBAR);
                toggle_repeat_button.active = false;
                toggle_repeat_button.draw_indicator = false;
                toggle_repeat_button.valign = Align.CENTER;
                toggle_repeat_button.halign = Align.CENTER;
                toggle_repeat_button.toggled.connect(() => {
                        playlist.toggle_repeat();
                        music.toggle_repeat();
                    });
            }

            controller_third_box.valign = Align.CENTER;
            controller_third_box.vexpand = false;
            controller_third_box.margin_right = 10;
            controller_third_box.pack_start(volume_button, false, false);
            controller_third_box.pack_start(toggle_shuffle_button, false, false);
            controller_third_box.pack_start(toggle_repeat_button, false, false);
        }

        controller.pack_start(artwork_button, false, false);
        controller.pack_start(controller_second_box, false, false);
        controller.pack_start(time_bar_box, true, true);
        controller.pack_start(controller_third_box, false, false);
    }

    //------------------------------------------------------------------------------
    // ブックマーク + ファインダーのボックス
    //------------------------------------------------------------------------------
    var finder_hbox = new Box(Orientation.HORIZONTAL, 1);
    {
        //------------------------------------------------------------------------------
        // ブックマークの作成
        //------------------------------------------------------------------------------
        var bookmark_revealer = new Revealer();
        {
            var bookmark_frame = new Frame(null);
            {
                var bookmark_scrolled = new ScrolledWindow(null, null);
                {
                    bookmark_tree = new TreeView();
                    {
                        var bookmark_title_col = new TreeViewColumn();
                        {
                            var bookmark_icon_cell = new CellRendererPixbuf();
                            var bookmark_label_cell = new CellRendererText();
                            {
                                bookmark_label_cell.family = "sans-serif";
                                bookmark_label_cell.language = Environ.get_variable(Environ.get(), "LANG");
                            }

                            bookmark_title_col.pack_start(bookmark_icon_cell, false);
                            bookmark_title_col.pack_start(bookmark_label_cell, true);
                            bookmark_title_col.add_attribute(bookmark_icon_cell, "icon-name", 0);
                            bookmark_title_col.add_attribute(bookmark_label_cell, "text", 1);
                            bookmark_title_col.set_title("label");
                            bookmark_title_col.sizing = TreeViewColumnSizing.AUTOSIZE;
                            bookmark_title_col.max_width = window_default_width / 4;
                            p_bookmark_title_col = bookmark_title_col;
                        }

                        var bookmark_del_col = new TreeViewColumn();
                        {
                            var bookmark_del_cell = new CellRendererPixbuf();

                            bookmark_del_col.pack_start(bookmark_del_cell, false);
                            bookmark_del_col.add_attribute(bookmark_del_cell, "icon-name", 4);
                            bookmark_del_col.set_title("del");
                        }

                        var bookmark_store = new TreeStore(5, typeof(string), typeof(string), typeof(string),
                                                           typeof(MenuType), typeof(string));
                        {
                            bookmark_store.append(out bookmark_root, null);
                            bookmark_store.set(bookmark_root,
                                               0, "user-bookmarks-symbolic", 1, "Bookmark",
                                               2, "", 3, MenuType.BOOKMARK, 4, "");

                            TreeIter bm_iter;
                            bookmark_store.append(out bm_iter, null);
                            bookmark_store.set(bm_iter, 0, null, 1, null, 2, null,
                                               3, MenuType.SEPARATOR, 4, "");
                            if (!options.use_csd) {
                                bookmark_store.append(out bm_iter, null);
                                bookmark_store.set(bm_iter,
                                                   0, "applications-system-symbolic", 1, "Config...",
                                                   2, null, 3, MenuType.CONFIG, 4, "");
                                bookmark_store.append(out bm_iter, null);
                                bookmark_store.set(bm_iter,
                                                   0, "help-faq-symbolic", 1, "About...",
                                                   2, null, 3, MenuType.ABOUT, 4, "");
                                bookmark_store.append(out bm_iter, null);
                                bookmark_store.set(bm_iter,
                                                   0, "application-exit-symbolic", 1, "Quit",
                                                   2, null, 3, MenuType.QUIT, 4, "");
                            }
                        }

                        Gtk.Callback menu_bookmark_reset = (bm) => {
                            TreeIter bm_iter;
                            bookmark_store.iter_children(out bm_iter, bookmark_root);

                            while (bookmark_store.iter_is_valid(bm_iter)) {
                                bookmark_store.remove(ref bm_iter);
                            }

                            foreach (string dir in dirs) {
                                string dir_basename = dir.slice(dir.last_index_of_char('/') + 1, dir.length);
                                bookmark_store.append(out bm_iter, bookmark_root);
                                bookmark_store.set(bm_iter, 0, "media-optical-symbolic", 1, dir_basename, 2, dir,
                                                   3, MenuType.FOLDER, 4, "");
                            }
                        };

                        bookmark_tree.activate_on_single_click = true;
                        bookmark_tree.headers_visible = false;
                        bookmark_tree.hover_selection = true;
                        bookmark_tree.reorderable = false;
                        bookmark_tree.show_expanders = true;
                        bookmark_tree.enable_tree_lines = false;
                        bookmark_tree.level_indentation = 0;

                        bookmark_tree.set_model(bookmark_store);
                        bookmark_tree.insert_column(bookmark_del_col, 1);
                        bookmark_tree.insert_column(bookmark_title_col, 0);

                        menu_bookmark_reset(bookmark_tree);

                        bookmark_tree.set_row_separator_func((model, iter) => {
                                Value menu_type;
                                model.get_value(iter, 3, out menu_type);
                                return ((MenuType) menu_type == MenuType.SEPARATOR);
                            });

                        bookmark_tree.get_selection().changed.connect(() => {
                                TreeSelection bookmark_selection = bookmark_tree.get_selection();
                                TreeStore? temp_store = (TreeStore) bookmark_tree.model;

                                temp_store.foreach((model, path, iter) => {
                                        Value type;
                                        temp_store.get_value(iter, 3, out type);
                                        if ((MenuType) type == MenuType.FOLDER) {
                                            string icon_name = "";
                                            if (dirs.length() > 0 && bookmark_selection.iter_is_selected(iter)) {
                                                icon_name = "list-remove-symbolic";
                                            } else {
                                                icon_name = "";
                                            }
                                            temp_store.set_value(iter, 4, icon_name);
                                        }
                                        return false;
                                    });
                            });

                        bookmark_tree.row_activated.connect((path, column) => {
                                Value dir_path;
                                Value bookmark_name;
                                TreeIter bm_iter;

                                debug("bookmark_tree_row_activated.");
                                bookmark_tree.model.get_iter(out bm_iter, path);
                                bookmark_tree.model.get_value(bm_iter, 3, out bookmark_name);

                                switch ((MenuType) bookmark_name) {
                                case MenuType.BOOKMARK:
                                    if (bookmark_tree.is_row_expanded(path)) {
                                        bookmark_tree.collapse_row(path);
                                    } else {
                                        bookmark_tree.expand_row(path, false);
                                    }
                                    break;
                                
                                case MenuType.FOLDER:
                                    bookmark_tree.model.get_value(bm_iter, 2, out dir_path);

                                    if (column.get_title() != "del") {
                                        finder.change_dir((string) dir_path);
                    
                                        if (options.use_csd) {
                                            win_header.set_title(program_name + ": " + current_dir);
                                        }
                                    } else {
                                        if (dirs.length() > 1) {
                                            dirs.remove_link(dirs.nth(path.get_indices()[1]));
                                            ((TreeStore)bookmark_tree.model).remove(ref bm_iter);
                                        }
                                    }
                                    break;
                                case MenuType.CONFIG:
                                    show_config_dialog(main_win);
                                    break;
                                case MenuType.ABOUT:
                                    show_about_dialog(main_win);
                                    break;
                                case MenuType.QUIT:
                                    application_quit();
                                    break;
                                }
                            });

                        bookmark_tree.expand_all();
                    }

                    bookmark_scrolled.shadow_type = ShadowType.NONE;
                    bookmark_scrolled.hscrollbar_policy = PolicyType.NEVER;
                    bookmark_scrolled.add(bookmark_tree);
                }

                bookmark_frame.set_shadow_type(ShadowType.NONE);
                bookmark_frame.get_style_context().add_class("sidebar");
                bookmark_frame.add(bookmark_scrolled);
            }

            bookmark_revealer.transition_type = RevealerTransitionType.SLIDE_LEFT;
            bookmark_revealer.reveal_child = true;
            bookmark_revealer.add(bookmark_frame);
            p_bookmark_revealer = bookmark_revealer;
        }

        //------------------------------------------------------------------------------
        // ファインダーの作成
        //------------------------------------------------------------------------------
        finder = new DPlayer.Finder();
        {
            finder.bookmark_button_clicked_func = (file_path) => {
                string file_name = file_path.slice(file_path.last_index_of_char('/') + 1, file_path.length);
                TreeStore temp_store = (TreeStore)bookmark_tree.model;
                dirs.append(file_path);
                TreeIter temp_iter;
                temp_store.append(out temp_iter, bookmark_root);
                temp_store.set(temp_iter,
                               0, "media-optical-symbolic",
                               1, file_name,
                               2, file_path,
                               3, MenuType.FOLDER,
                               4, "");
            };

            finder.play_button_clicked_func = (file_path) => {

                finder.change_cursor(Gdk.CursorType.WATCH);
                    
                if (music.playing) {
                    music.quit();
                }
                    
                Timeout.add(10, () => {
                        if (music.playing) {
                            return Source.CONTINUE;
                        } else {
                            debug("file_path: %s", file_path);
                            playlist.new_list_from_path(file_path);
                            var file_path_list = playlist.get_file_path_list();
                            if (FileUtils.test(file_path, FileTest.IS_REGULAR)) {
                                music.start(ref file_path_list, options.ao_type);
                                int index = playlist.get_index_from_path(file_path);
                                if (index > 0) {
                                    music.play_next(index);
                                }
                            } else {
                                music.start(ref file_path_list, options.ao_type);
                            }
                            p_finder_next_button->visible = true;
                            ((Gtk.Image)play_pause_button.icon_widget).icon_name = "media-playback-pause-symbolic";
                            header_sidebar_button.image = view_grid_image;
                            header_sidebar_button.sensitive = true;
                            stack.show_playlist();
                            finder.change_cursor(Gdk.CursorType.LEFT_PTR);
                            return Source.REMOVE;
                        }
                    });
            };

            finder.add_button_clicked_func = (file_path) => {
                playlist.append_list_from_path(file_path);
                List<string> file_list = playlist.get_file_path_list();
                music.set_file_list(ref file_list);
                next_track_button.sensitive = true;
            };

            finder.use_popover = false;
        }
    
        finder_hbox.pack_start(bookmark_revealer, false, false);
        finder_hbox.pack_start(finder, true, true);
    }

    //----------------------------------------------------------------------------------
    // プレイリスト画面作成
    //----------------------------------------------------------------------------------
    var playlist_view_container = new ScrolledWindow(null, null);
    {
        playlist = new PlaylistBox();
        {
            playlist.image_size = options.playlist_image_size;
            playlist.list_box.row_activated.connect((row) => {
                    int index = row.get_index();
                    debug("playlist view was clicked (row_activated at %u).", index);
                    int step = ((int) index) - ((int) playlist.get_track());
                        
                    if (step == 0) {
                        music.pause();
                        playlist.toggle_status();
                        if (music.paused) {
                            ((Gtk.Image)play_pause_button.icon_widget).icon_name = "media-playback-start-symbolic";
                        } else {
                            ((Gtk.Image)play_pause_button.icon_widget).icon_name = "media-playback-pause-symbolic";
                        }
                    } else {
                        debug("playlist restarted from track %d", index);
                        if (step > 0) {
                            music.play_next(step);
                        } else if (step < 0) {
                            music.play_prev(-step);
                        }
                        music.paused = false;
                    }

                    return;
                });
        }
        playlist_view_container.add(playlist);
    }

    //----------------------------------------------------------------------------------
    // アートワーク表示画面作成
    //----------------------------------------------------------------------------------
    music_view_overlay = new Overlay();
    {
        var music_view_close_button = new Button.from_icon_name("window-close-symbolic", IconSize.BUTTON);
        {
            music_view_close_button.halign = Align.END;
            music_view_close_button.valign = Align.START;
            music_view_close_button.margin = 10;
            music_view_close_button.clicked.connect(() => {
                    artwork_button.visible = true;
                    music_view_overlay.visible = false;
                    header_sidebar_button.sensitive = true;
                });
            p_music_view_close_button = music_view_close_button;
        }

        music_view_container = new ScrolledWindow(null, null);
        {
            music_view_container.get_style_context().add_class("artwork_background");
        }

        music_view_artwork = new Image();
        {
            music_view_artwork.margin = 0;
            music_view_container.add(music_view_artwork);
        }

        music_view_overlay.add(music_view_container);
        music_view_overlay.add_overlay(music_view_close_button);
        music_view_overlay.set_overlay_pass_through(music_view_close_button, true);
    }

    //----------------------------------------------------------------------------------
    // 音楽再生機能の実装
    //----------------------------------------------------------------------------------
    music = new Music();
    {
        music.set_on_quit_func((pid, status) => {
                time_bar.fraction = 0.0;
                time_label_set(0);

                ((Gtk.Image)play_pause_button.icon_widget).icon_name = "media-playback-start-symbolic";
            });
    
        music.set_on_start_func((track_number, file_path) => {
                debug("on start func start");

                DFileInfo file_info = playlist.nth_track_data(track_number);

                music_title.label = (file_info.title != null) ? file_info.title : file_info.name;
                if (options.use_csd) {
                    win_header.set_title(music_title.label);
                } else {
                    main_win.title = music_title.label;
                }
                music_total_time = file_info.time_length;
                music_total_time_seconds = MyUtils.TimeUtils.minutes_to_seconds(music_total_time);
                music_time_position = 0.0;
                if (music_total_time.length > 5) {
                    time_label_set = (current_time) => {
                        double current_hours = Math.floor(current_time / 360);
                        double current_minutes = Math.floor(current_time / 60);
                        double current_seconds = Math.floor(current_time % 60);
                        double current_milliseconds = Math.floor(current_time * 10 % 10);
                        time_label_current.label = "%02.0f:%02.0f:%02.0f.%01.0f".printf(current_hours,
                                                                                        current_minutes,
                                                                                        current_seconds,
                                                                                        current_milliseconds);
                        double rest_time_total = music_total_time_seconds - current_time;
                        double rest_hours = Math.floor(rest_time_total / 360);
                        double rest_minutes = Math.floor(rest_time_total / 60);
                        double rest_seconds = Math.floor(rest_time_total % 60);
                        double rest_milliseconds = Math.floor(current_time * 10 % 10);
                        time_label_rest.label = "%02.0f:%02.0f:%02.0f".printf(rest_hours,
                                                                              rest_minutes,
                                                                              rest_seconds);
                    };
                } else {
                    time_label_set = (current_time) => {
                        double current_minutes = Math.floor(current_time / 60);
                        double current_seconds = Math.floor(current_time % 60);
                        double current_milliseconds = Math.floor(current_time * 10 % 10);
                        time_label_current.label = "%02.0f:%02.0f.%01.0f".printf(current_minutes,
                                                                                 current_seconds,
                                                                                 current_milliseconds);
                        double rest_time_total = music_total_time_seconds - current_time;
                        double rest_minutes = Math.floor(rest_time_total / 60);
                        double rest_seconds = Math.floor(rest_time_total % 60);
                        time_label_rest.label = "%02.0f:%02.0f".printf(rest_minutes,
                                                                          rest_seconds);
                    };
                }
                time_label_rest.label = music_total_time;
                time_label_set(0);
                time_bar.set_fraction(0.0);
                Timeout.add(100, () => {
                        if (track_number != music.get_current_track_number() || !music.playing) {
                            return Source.REMOVE;
                        }

                        if (!music.paused) {
                            music_time_position += 0.1;
                            time_label_set(music_time_position);
                            time_bar.set_fraction(music_time_position / music_total_time_seconds);
                        }
                        return Source.CONTINUE;
                    }, Priority.DEFAULT);

                ((Gtk.Image)play_pause_button.icon_widget).icon_name = "media-playback-pause-symbolic";

                play_pause_button.sensitive = true;
                next_track_button.sensitive = !playlist.track_is_last();
                prev_track_button.sensitive = true;

                playlist.set_track(track_number);
                
                debug("artwork_max_size: " + artwork_max_size.to_string());
                current_playing_artwork = file_info.artwork;
                if (current_playing_artwork != null) {
                    artwork.set_from_pixbuf(MyUtils.PixbufUtils.scale_limited(current_playing_artwork,
                                                                              options.thumbnail_size));
                    if (!music_view_artwork.visible) {
                        artwork_button.visible = true;
                        debug("make artwork button visible");
                    }
                    Timeout.add(10, () => {
                            debug("enter timeout artwork size");
                            int size = int.min(music_view_container.get_allocated_width(),
                                               music_view_container.get_allocated_height());
                            music_view_artwork.pixbuf = MyUtils.PixbufUtils.scale_limited(current_playing_artwork,
                                                                                         size);
                            debug("music view artwork size: " + size.to_string());
                            return Source.REMOVE;
                        });
                } else {
                    artwork_button.visible = false;
                    music_view_artwork.set_from_icon_name("audio-x-generic", IconSize.LARGE_TOOLBAR);
                }

            });

        music.set_on_end_func((track_number, track_name) => {
                playlist.set_track(-1);
            });
    }

    //----------------------------------------------------------------------------------
    // メインウィンドウの作成
    //----------------------------------------------------------------------------------
    main_win = new Window();
    {
        var top_box = new Box(Orientation.VERTICAL, 0);
        {
            var main_overlay = new Overlay();
            {
                stack = new DPlayerStack(finder_hbox, playlist_view_container);
                
                main_overlay.add(stack);
                main_overlay.add_overlay(music_view_overlay);
            }
            
            top_box.pack_start(main_overlay, true, true);
            top_box.pack_start(controller, false, false);
        }

        main_win.add(top_box);
        if (options.use_csd) {
            main_win.set_titlebar(win_header);
        } else {
            main_win.title = "dplayer : directory player";
        }
        main_win.border_width = 0;
        main_win.window_position = WindowPosition.CENTER;
        main_win.resizable = true;
        main_win.has_resize_grip = true;
        main_win.set_default_size(window_default_width, window_default_height);

        main_win.destroy.connect(application_quit);
        main_win.configure_event.connect((cr) => {
                if (music_view_overlay.visible && current_playing_artwork != null) {
                    int size = int.min(music_view_container.get_allocated_width(),
                                       music_view_container.get_allocated_height());
                    music_view_artwork.pixbuf = MyUtils.PixbufUtils.scale_limited(current_playing_artwork, size);
                }
                p_bookmark_title_col->max_width = main_win.get_allocated_width() / 4;
                return false;
            });

        main_win.show_all();
    }

    //----------------------------------------------------------------------------------
    // スタイルシートの読み込み
    //----------------------------------------------------------------------------------
    if (FileUtils.test(css_path, FileTest.EXISTS)) {
        Gdk.Screen win_screen = main_win.get_screen();
        CssProvider css_provider = new CssProvider();
        try {
            css_provider.load_from_path(css_path);
        } catch (Error e) {
            stderr.printf("ERROR: failed to create a window");
            return 1;
        }
        Gtk.StyleContext.add_provider_for_screen(win_screen, css_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
    }
    
    //----------------------------------------------------------------------------------
    // プログラムの開始
    //----------------------------------------------------------------------------------
    artwork_button.visible = false;
    music_view_overlay.visible = false;
    music_view_artwork.visible = false;
    p_finder_next_button->visible = false;
    finder.hide_while_label();
    header_sidebar_button.image = view_list_image;
    header_sidebar_button.sensitive = false;
    stack.show_finder();

    Gtk.main();

    //----------------------------------------------------------------------------------
    // 終了処理
    //----------------------------------------------------------------------------------
    config_file_contents = "";

    foreach (string dir in dirs) {
        config_file_contents += "dir=" + dir + "\n";
    }

    config_file_contents += "ao_type=" + options.ao_type + "\n";

    config_file_contents += "thumbnail_size=" + options.thumbnail_size.to_string() + "\n";

    config_file_contents += "use_csd=" + (options.use_csd ? "true\n" : "false\n");

    config_file_contents += "cwd=" + current_dir + "\n";

    config_file_contents += "playlist_image_size=%d\n".printf(options.playlist_image_size);
    
    try {
        FileUtils.set_contents(config_file_path, config_file_contents);
    } catch (Error e) {
        stderr.printf("Error: can not write to config file.\n");
        Process.exit(1);
    }

    return 0;
}
