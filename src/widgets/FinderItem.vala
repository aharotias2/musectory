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

using Gtk;

namespace Tatam {
    private class FinderItem : FlowBoxChild {
        public static Gdk.Pixbuf? file_pixbuf;
        public static Gdk.Pixbuf? cd_pixbuf;
        public static Gdk.Pixbuf? folder_pixbuf;
        public static Gdk.Pixbuf? parent_pixbuf;
        
        public int icon_size { get; set; }

        private Button icon_button;
        private Button add_button;
        private Button bookmark_button;
        private Button play_button;
        private Image icon_image;
        private Tatam.FileInfo file_info;
        
        private Gdk.Pixbuf? icon_pixbuf;
        private Image? mini_icon;

        public signal void clicked(string file_path);
        public signal void bookmark_button_clicked(string file_path);
        public signal void add_button_clicked(string file_path);
        public signal void play_button_clicked(string file_path);

        public FinderItem(Tatam.FileInfo file_info, int icon_size, bool use_popover = true) {
            this.file_info = file_info;
            this.icon_size = icon_size;
            debug("file_path: " + file_info.path);
            
            var ev_box = new EventBox();
            {
                var widget_overlay2 = new Overlay();
                {           
                    icon_button = new Button();
                    {
                        var widget_overlay1 = new Overlay();
                        {
                            icon_pixbuf = create_icon_pixbuf();

                            icon_image = new Image.from_pixbuf(
                                Tatam.PixbufUtils.scale_limited(icon_pixbuf, this.icon_size)
                                );
                            {
                                icon_image.get_style_context().add_class(StyleClass.FINDER_ICON);
                            }
                            
                            var item_label = new Label(file_info.name);
                            {
                                item_label.ellipsize = Pango.EllipsizeMode.END;
                                item_label.lines = 5;
                                item_label.single_line_mode = false;
                                item_label.max_width_chars = 20;
                                item_label.margin = 0;
                                item_label.wrap = true;
                                item_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
                                item_label.valign = Align.END;
                                item_label.get_style_context().add_class(StyleClass.FINDER_ITEM_LABEL);
                            }

                            Image mini_icon = null;
                            {
                                if (file_info.type == Tatam.FileType.FILE) {
                                    mini_icon = new Image.from_icon_name(IconName.AUDIO_FILE,
                                                                         IconSize.LARGE_TOOLBAR);
                                } else if (file_info.type == Tatam.FileType.DISC) {
                                    mini_icon = new Image.from_icon_name(IconName.FOLDER,
                                                                         IconSize.LARGE_TOOLBAR);
                                    mini_icon.visible = false;
                                }
                                
                                if (mini_icon != null) {
                                    mini_icon.halign = Align.START;
                                    mini_icon.valign = Align.START;
                                }
                            }
                            
                            widget_overlay1.add(icon_image);
                            widget_overlay1.add_overlay(item_label);
                            widget_overlay1.set_overlay_pass_through(item_label, true);

                            if (mini_icon != null) {
                                widget_overlay1.add_overlay(mini_icon);
                                widget_overlay1.set_overlay_pass_through(mini_icon, true);
                            }
                        }

                        icon_button.hexpand = false;
                        icon_button.vexpand = false;
                        icon_button.border_width = 0;
                        icon_button.get_style_context().add_class(StyleClass.FLAT);
                        icon_button.add(widget_overlay1);
                        icon_button.clicked.connect(() => {
                                clicked(file_info.path);
                            });
                    }

                    var button_box = new Box(Orientation.HORIZONTAL, 5);
                    {
                        bookmark_button = new Button.from_icon_name(IconName.Symbolic.USER_BOOKMARKS,
                                                                    IconSize.SMALL_TOOLBAR);
                        {
                            bookmark_button.valign = Align.CENTER;
                            bookmark_button.visible = false;
                            bookmark_button.get_style_context().add_class(StyleClass.FINDER_BUTTON);
                            bookmark_button.clicked.connect(() => {
                                    bookmark_button_clicked(file_info.path);
                                });
                        }

                        add_button = new Button.from_icon_name(IconName.Symbolic.LIST_ADD,
                                                               IconSize.SMALL_TOOLBAR);
                        {
                            add_button.valign = Align.CENTER;
                            add_button.visible = false;
                            add_button.get_style_context().add_class(StyleClass.FINDER_BUTTON);
                            add_button.clicked.connect(() => {
                                    add_button_clicked(file_info.path);
                                });
                        }

                        play_button = new Button.from_icon_name(IconName.Symbolic.MEDIA_PLAYBACK_START,
                                                                IconSize.LARGE_TOOLBAR);
                        {
                            play_button.valign = Align.CENTER;
                            play_button.visible = false;
                            play_button.get_style_context().add_class(StyleClass.FINDER_BUTTON);
                            play_button.clicked.connect(() => {
                                    play_button_clicked(file_info.path);
                                });
                        }

                        button_box.halign = Align.CENTER;
                        button_box.valign = Align.CENTER;
                        if (file_info.type != Tatam.FileType.PARENT) {
                            if (use_popover) {
                                if (file_info.type == Tatam.FileType.DIRECTORY
                                    || file_info.type == Tatam.FileType.DISC)
                                {
                                    button_box.pack_start(
                                        add_popover_to_button(bookmark_button, "Add to bookmark list"),
                                        false, false);
                                }
                                button_box.pack_start(
                                    add_popover_to_button(play_button, "Play it"),
                                    false, false);
                                button_box.pack_start(
                                    add_popover_to_button(add_button, "Add to playlist"),
                                    false, false);
                            } else {
                                if (file_info.type == Tatam.FileType.DIRECTORY
                                    || file_info.type == Tatam.FileType.DISC)
                                {
                                    button_box.pack_start(bookmark_button, false, false);
                                }
                                button_box.pack_start(play_button, false, false);
                                button_box.pack_start(add_button, false, false);
                            }
                        }
                    }

                    widget_overlay2.add(icon_button);
                    widget_overlay2.add_overlay(button_box);
                }
            
                ev_box.enter_notify_event.connect((event) => {
                        show_buttons();
                        return Source.CONTINUE;
                    });
                ev_box.leave_notify_event.connect((event) => {
                        hide_buttons();
                        return Source.CONTINUE;
                    });

                ev_box.add(widget_overlay2);
            }
            
            vexpand = false;
            hexpand = false;
            add(ev_box);
        }

        public void hide_buttons() {
            add_button.visible = bookmark_button.visible = play_button.visible = false;
        }

        public void show_buttons() {
            add_button.visible = bookmark_button.visible = play_button.visible = true;
        }

        public void set_image_size(int size) {
            this.icon_size = size;
            icon_image.pixbuf = Tatam.PixbufUtils.scale_limited(icon_pixbuf, this.icon_size);
        }

        private EventBox add_popover_to_button(Button button, string pop_text) {
            var pop = new Popover(button);
            {
                pop.add(new Label(pop_text));
                pop.set_default_widget(this);
                pop.modal = false;
                pop.transitions_enabled = false;
                pop.position = PositionType.BOTTOM;
                pop.show_all();
            }
            
            var ev_box = new EventBox();
            {
                ev_box.add(button);
                ev_box.enter_notify_event.connect((event) => {
                        pop.visible = true;
                        return Source.CONTINUE;
                    });
            
                ev_box.leave_notify_event.connect((event) => {
                        pop.visible = false;
                        return Source.CONTINUE;
                    });
            }
            
            return (owned) ev_box;
        }
        
        private Gdk.Pixbuf? create_icon_pixbuf() {
            switch (file_info.type) {
            case Tatam.FileType.DISC:
                debug("file_info.type: disc");
                load_artwork_async.begin((res, obj) => {
                        Gdk.Pixbuf? artwork_pixbuf = load_artwork_async.end(obj);
                        if (artwork_pixbuf != null) {
                            icon_pixbuf = artwork_pixbuf;
                            icon_image.pixbuf = Tatam.PixbufUtils.scale_limited(icon_pixbuf, this.icon_size);
                            if (mini_icon != null) {
                                mini_icon.visible = true;
                            }
                        }
                    });
                return cd_pixbuf;

            case Tatam.FileType.DIRECTORY:
                debug("file_info.type: directory");
                return folder_pixbuf;

            case Tatam.FileType.PARENT:
                debug("file_info.type: parent");
                return parent_pixbuf;

            case Tatam.FileType.FILE:
            default:
                debug("file_info.type: file");
                if (file_info.artwork != null) {
                    return file_info.artwork;
                } else {
                    return file_pixbuf;
                }
            }
        }

        private async Gdk.Pixbuf? load_artwork_async() {
            string thread_name = "thread_artwork_of_" + file_info.name;
            Thread<Gdk.Pixbuf?> thread = new Thread<Gdk.Pixbuf?>(thread_name, () => {
                    debug("thread starts");
                    Gdk.Pixbuf? artwork_pixbuf = null;
                    try {
                        artwork_pixbuf = Files.load_first_artwork(file_info.path, icon_size);
                    } catch (Tatam.Error e) {
                        stderr.printf(@"Tatam.Error: $(e.message)\n");
                    } catch (FileError e) {
                        stderr.printf(@"FileError: $(e.message)\n");
                    }
                    debug("thread ends %s of %s",
                          (artwork_pixbuf != null ? "icon has been loaded" : "icon is null"),
                          file_info.path);
                    Idle.add(load_artwork_async.callback);
                    return artwork_pixbuf;
                });
            yield;
            return thread.join();
        }
    }
}
