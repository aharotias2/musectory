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
    public interface ControllerInterface {
        public const double SMALL_STEP_MILLISECONDS = 100.0;
        public const double BIG_STEP_MILLISECONDS = 10000.0;
        public signal void artwork_clicked();
        public signal void play_button_clicked();
        public signal void pause_button_clicked();
        public signal void next_button_clicked();
        public signal void prev_button_clicked();
        public signal void time_position_changed(double value);
        public signal void volume_changed(double value);
        public signal void shuffle_button_toggled(bool shuffle_on);
        public signal void repeat_button_toggled(bool repeat_on);

        public abstract ControllerState play_pause_button_state { get; set; }
        public abstract uint music_total_time { get; set; }
        public abstract uint music_current_time { get; set; }
        public abstract string music_title { get; set; }
        public abstract uint artwork_size { get; set; }
        public abstract double volume { get; set; }

        public abstract void set_artwork(Gdk.Pixbuf pixbuf);
        public abstract void show_buttons();
        public abstract void hide_buttons();
        public abstract void show_artwork();
        public abstract void hide_artwork();
        public abstract void activate_buttons(bool track_is_first, bool track_is_last);
        public abstract void deactivate_buttons();
        public abstract void pause();
        public abstract void unpause();
    }

    public class Controller : Bin, ControllerInterface {
        private Button artwork_button;
        private Image artwork;
        private ToolButton play_pause_button;
        private ToolButton next_track_button;
        private ToolButton prev_track_button;
        private Label music_title_label;
        private Scale time_bar;
        private Label time_label_current;
        private Label time_label_rest;
        private ToggleButton toggle_shuffle_button;
        private ToggleButton toggle_repeat_button;
        private Scale volume_bar;
        
        private ControllerState play_pause_button_state_value;
        private SmallTime music_total_time_value;
        private SmallTime music_current_time_value;
        private SmallTime music_rest_time_value;
        private uint artwork_size_value;
        private bool running;
        private Gdk.Pixbuf? original_pixbuf;
        
        public ControllerState play_pause_button_state {
            get {
                return play_pause_button_state_value;
            }

            set {
                if (play_pause_button_state_value != value) {
                    play_pause_button_state_value = value;
                    switch (play_pause_button_state) {
                    case ControllerState.PLAY:
                        running = true;
                        Image? icon = play_pause_button.icon_widget as Image;
                        if (icon != null) {
                            icon.icon_name = IconName.Symbolic.MEDIA_PLAYBACK_PAUSE;
                        }
                        Timeout.add(100, () => {
                                if (running) {
                                    music_current_time += 100;
                                }
                                if (music_current_time_value.milliseconds
                                    >= music_total_time_value.milliseconds) {
                                    play_pause_button_state = ControllerState.FINISHED;
                                }
                                return running;
                            });
                        debug("play_pause_button_state was set to PLAY");
                        break;
                    case ControllerState.PAUSE:
                        running = false;
                        Image? icon = play_pause_button.icon_widget as Image;
                        if (icon != null) {
                            icon.icon_name = IconName.Symbolic.MEDIA_PLAYBACK_START;
                        }
                        debug("play_pause_button_state was set to PAUSE");
                        break;
                    case ControllerState.FINISHED:
                        running = false;
                        Image? icon = play_pause_button.icon_widget as Image;
                        if (icon != null) {
                            icon.icon_name = IconName.Symbolic.MEDIA_PLAYBACK_START;
                        }
                        music_current_time = 0;
                        debug("play_pause_button_state was set to FINISHED");
                        break;
                    }
                }
            }
        }

        public uint music_total_time {
            get {
                return music_total_time_value.milliseconds;
            }
            set {
                music_total_time_value = new SmallTime.from_milliseconds(value);
                music_current_time_value = new SmallTime(music_total_time_value.format_type);
                music_rest_time_value = new SmallTime.from_milliseconds(value);
                time_label_rest.label = music_rest_time_value.to_string();
                time_label_current.label = music_current_time_value.to_string();
                time_bar.adjustment = new Adjustment(0.0, 0.0, (double) music_total_time_value.milliseconds,
                                                     SMALL_STEP_MILLISECONDS, BIG_STEP_MILLISECONDS,
                                                     100.0);
                debug("music_total_time was set to %s", music_total_time_value.to_string());
            }
        }
        
        public uint music_current_time {
            get {
                return music_current_time_value.milliseconds;
            }
            set {
                if (value > music_total_time_value.milliseconds) {
                    value = music_total_time_value.milliseconds;
                }
                music_current_time_value.milliseconds = value;
                music_rest_time_value.milliseconds
                = music_total_time_value.milliseconds
                - music_current_time_value.milliseconds;
                time_label_current.label = music_current_time_value.to_string();
                time_label_rest.label = music_rest_time_value.to_string();
                if (value != (uint) time_bar.get_value()) {
                    time_bar.set_value(value);
                }
            }
        }

        public string music_title {
            get {
                return music_title_label.label;
            }
            set {
                music_title_label.label = value;
            }
        }
        
        public uint artwork_size {
            get {
                return artwork_size_value;
            }
            set {
                artwork_size_value = value;
                if (original_pixbuf != null) {
                    artwork.pixbuf = PixbufUtils.scale_limited(original_pixbuf, artwork_size_value);
                }
            }
        }

        public double volume {
            get {
                return volume_bar.get_value();
            }
            set {
                volume_bar.set_value(value);
            }
        }
        
        public void set_artwork(Gdk.Pixbuf pixbuf) {
            original_pixbuf = pixbuf;
            Gdk.Pixbuf resized_pixbuf = Tatam.PixbufUtils.scale_limited(original_pixbuf, (int) this.artwork_size);
            artwork.pixbuf = resized_pixbuf;
        }
        
        public Controller() {
            Box main_box = new Box(Orientation.HORIZONTAL, 2);
            {
                artwork_button = new Button();
                {
                    artwork = new Image();
                    {
                        artwork.margin = 0;
                    }

                    artwork_button.margin = 0;
                    artwork_button.relief = ReliefStyle.NONE;
                    artwork_button.get_style_context().add_class(StyleClass.FLAT);
                    artwork_button.add(artwork);
                    artwork_button.clicked.connect(() => {
                            artwork_clicked();
                        });
                }

                var controller_second_box = new Box(Orientation.HORIZONTAL, 2);
                {
                    play_pause_button = new ToolButton(
                        new Image.from_icon_name(IconName.Symbolic.MEDIA_PLAYBACK_START,
                                                 IconSize.SMALL_TOOLBAR), null
                        );
                    {
                        play_pause_button.clicked.connect(() => {
                                switch (play_pause_button_state) {
                                case ControllerState.FINISHED:
                                case ControllerState.PAUSE: {
                                    unpause();
                                    play_button_clicked();
                                } break;
                                case ControllerState.PLAY: {
                                    pause();
                                    pause_button_clicked();
                                } break;
                                }
                            });
                    }

                    next_track_button = new ToolButton(
                        new Image.from_icon_name(IconName.Symbolic.MEDIA_SKIP_FORWARD,
                                                 IconSize.SMALL_TOOLBAR), null);
                    {
                        next_track_button.sensitive = false;
                        next_track_button.clicked.connect(() => {
                                next_button_clicked();
                            });
                    }

                    prev_track_button = new ToolButton(
                        new Image.from_icon_name(IconName.Symbolic.MEDIA_SKIP_BACKWARD,
                                                 IconSize.SMALL_TOOLBAR), null);
                    {
                        prev_track_button.sensitive = false;
                        prev_track_button.clicked.connect(() => {
                                prev_button_clicked();
                            });
                    }

                    controller_second_box.valign = Align.CENTER;
                    controller_second_box.vexpand = false;
                    controller_second_box.margin_end = 10;
                    controller_second_box.get_style_context().add_class(StyleClass.LINKED);
                    controller_second_box.pack_start(prev_track_button, false, false);
                    controller_second_box.pack_start(play_pause_button, false, false);
                    controller_second_box.pack_start(next_track_button, false, false);
                }

                var time_bar_box = new Box(Orientation.VERTICAL, 2);
                {
                    music_title_label = new Label("");
                    {
                        music_title_label.justify = Justification.LEFT;
                        music_title_label.single_line_mode = false;
                        music_title_label.lines = 4;
                        music_title_label.wrap = true;
                        music_title_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
                        music_title_label.ellipsize = Pango.EllipsizeMode.END;
                        music_title_label.margin_start = 5;
                        music_title_label.margin_end = 5;
                    }

                    time_bar = new Scale.with_range(Orientation.HORIZONTAL, 0.0, 1000.0, 100.0);
                    {
                        time_bar.set_size_request(-1, 12);
                        time_bar.draw_value = false;
                        time_bar.has_origin = true;
                        time_bar.set_increments(SMALL_STEP_MILLISECONDS, BIG_STEP_MILLISECONDS);
                        time_bar.value_changed.connect(() => {
                                music_current_time = (uint) time_bar.get_value();
                            });
                        time_bar.change_value.connect((scroll_type, new_value) => {
                                debug("change_value %f, %f", new_value, time_bar.get_value());
                                time_position_changed(time_bar.get_value());
                                return false;
                            });
                    }

                    var time_label_box = new Box(Orientation.HORIZONTAL, 0);
                    {
                        time_label_current = new Label("0:00:00");
                        {
                            time_label_current.get_style_context().add_class(StyleClass.TIME_LABEL_CURRENT);
                        }
                        time_label_rest = new Label("0:00:00");
                        {
                            time_label_rest.get_style_context().add_class(StyleClass.TIME_LABEL_REST);
                        }
                        time_label_box.pack_start(time_label_current, false, false);
                        time_label_box.pack_end(time_label_rest, false, false);
                    }
            
                    time_bar_box.valign = Align.CENTER;
                    time_bar_box.pack_start(music_title_label, false, false);
                    time_bar_box.pack_start(time_bar, true, false);
                    time_bar_box.pack_start(time_label_box, true, false);
                }

                var controller_third_box = new Box(Orientation.HORIZONTAL, 2);
                {
                    var volume_button = new ToolButton(
                        new Image.from_icon_name(IconName.Symbolic.AUDIO_VOLUME_MEDIUM, IconSize.SMALL_TOOLBAR), null);
                    {
                        var popover = new Popover(volume_button);
                        {
                            volume_bar = new Scale.with_range(Orientation.VERTICAL, 0.0, 1.0, 0.01);
                            {
                                volume_bar.set_value(0.5);
                                volume_bar.has_origin = true;
                                volume_bar.set_inverted(true);
                                volume_bar.draw_value = false;
                                volume_bar.value_pos = PositionType.BOTTOM;
                                volume_bar.margin = 5;
                                volume_bar.value_changed.connect(() => {
                                        volume_changed(volume_bar.get_value());
                                        var icon = ((Image) volume_button.icon_widget);
                                        if (volume_bar.get_value() == 0.0) {
                                            icon.icon_name = IconName.Symbolic.AUDIO_VOLUME_MUTED;
                                        } else if (volume_bar.get_value() < 0.35) {
                                            icon.icon_name = IconName.Symbolic.AUDIO_VOLUME_LOW;
                                        } else if (volume_bar.get_value() < 0.75) {
                                            icon.icon_name = IconName.Symbolic.AUDIO_VOLUME_MEDIUM;
                                        } else {
                                            icon.icon_name = IconName.Symbolic.AUDIO_VOLUME_HIGH;
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
                        toggle_shuffle_button.image = new Image.from_icon_name(IconName.Symbolic.MEDIA_PLAYLIST_SHUFFLE,
                                                                               IconSize.SMALL_TOOLBAR);
                        toggle_shuffle_button.active = false;
                        toggle_shuffle_button.draw_indicator = false;
                        toggle_shuffle_button.valign = Align.CENTER;
                        toggle_shuffle_button.halign = Align.CENTER;
                        toggle_shuffle_button.toggled.connect(() => {
                                shuffle_button_toggled(toggle_shuffle_button.active);
                            });
                    }

                    toggle_repeat_button = new ToggleButton();
                    {
                        toggle_repeat_button.image = new Image.from_icon_name(IconName.Symbolic.MEDIA_PLAYLIST_REPEAT,
                                                                              IconSize.SMALL_TOOLBAR);
                        toggle_repeat_button.active = false;
                        toggle_repeat_button.draw_indicator = false;
                        toggle_repeat_button.valign = Align.CENTER;
                        toggle_repeat_button.halign = Align.CENTER;
                        toggle_repeat_button.toggled.connect(() => {
                                repeat_button_toggled(toggle_repeat_button.active);
                            });
                    }

                    controller_third_box.valign = Align.CENTER;
                    controller_third_box.vexpand = false;
                    controller_third_box.margin_end = 10;
                    controller_third_box.pack_start(volume_button, false, false);
                    controller_third_box.pack_start(toggle_shuffle_button, false, false);
                    controller_third_box.pack_start(toggle_repeat_button, false, false);
                }

                main_box.margin = 4;
                main_box.pack_start(artwork_button, false, false);
                main_box.pack_start(controller_second_box, false, false);
                main_box.pack_start(time_bar_box, true, true);
                main_box.pack_start(controller_third_box, false, false);
            }

            add(main_box);
            artwork_size_value = 128;
            music_total_time_value = new SmallTime(0);
            music_current_time_value = new SmallTime(0);
            music_rest_time_value = new SmallTime(0);
            play_pause_button_state = ControllerState.FINISHED;
            deactivate_buttons();
        }

        public void show_buttons() {
            prev_track_button.visible = true;
            next_track_button.visible = true;
            toggle_repeat_button.visible = true;
            toggle_shuffle_button.visible = true;
            artwork_button.sensitive = true;
        }
        
        public void hide_buttons() {
            prev_track_button.visible = false;
            next_track_button.visible = false;
            toggle_repeat_button.visible = false;
            toggle_shuffle_button.visible = false;
            artwork_button.sensitive = false;
        }

        public void show_artwork() {
            this.artwork_button.visible = true;
        }
        
        public void hide_artwork() {
            this.artwork_button.visible = false;
        }

        public void activate_buttons(bool track_is_first, bool track_is_last) {
            play_pause_button.sensitive = true;
            prev_track_button.sensitive = !track_is_first;
            next_track_button.sensitive = !track_is_last;
        }
        
        public void deactivate_buttons() {
            play_pause_button.sensitive = false;
            prev_track_button.sensitive = false;
            next_track_button.sensitive = false;
        }

        public void pause() {
            play_pause_button_state = ControllerState.PAUSE;
        }

        public void unpause() {
            play_pause_button_state = ControllerState.PLAY;
        }
    }
}
