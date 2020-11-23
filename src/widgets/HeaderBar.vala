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
    public interface HeaderBarInterface {
        public abstract SwitchButtonState switch_button_state { get; set; }
        public abstract FoldButtonState fold_button_state { get; set; }
        public abstract string? switch_button_icon_name { owned get; set; }

        public signal void switch_button_clicked(SwitchButtonState switch_button_state);
        public signal void add_button_clicked();
        public signal void fold_button_clicked(FoldButtonState fold_button_state);
        public signal void about_button_clicked();

        public abstract void disable_switch_button();
        public abstract void enable_switch_button();
        public abstract void show_add_button();
        public abstract void hide_add_button();
    }

    public class HeaderBar : Gtk.HeaderBar, HeaderBarInterface {
        public enum SwitchButtonState {
            FINDER, PLAYLIST
        }
        public enum FoldButtonState {
            OPENED, FOLDED
        }

        private Button switch_button;
        private Button add_button;
        private ToggleButton fold_button;
        private Button about_button;

        private SwitchButtonState switch_button_state_value;

        public SwitchButtonState switch_button_state {
            get {
                return switch_button_state_value;
            }

            set {
                Image? image = this.switch_button.image as Image;
                switch (switch_button_state_value = value) {
                case SwitchButtonState.FINDER:
                    if (image != null) {
                        image.icon_name = IconName.Symbolic.VIEW_LIST;
                    }
                    this.switch_button.tooltip_text = Text.TOOLTIP_SHOW_PLAYLIST;
                    break;
                case SwitchButtonState.PLAYLIST:
                    if (image != null) {
                        image.icon_name = IconName.Symbolic.GO_PREVIOUS;
                    }
                    this.switch_button.tooltip_text = Text.TOOLTIP_SHOW_FINDER;
                    break;
                }
            }
        }

        private FoldButtonState fold_button_state_value;

        public FoldButtonState fold_button_state {
            get {
                return fold_button_state_value;
            }

            set {
                switch (fold_button_state_value = value) {
                case FoldButtonState.OPENED:
                    this.fold_button.image = new Image.from_icon_name(IconName.Symbolic.GO_DOWN, IconSize.BUTTON);
                    this.switch_button.sensitive = false;
                    break;
                case FoldButtonState.FOLDED:
                    this.fold_button.image = new Image.from_icon_name(IconName.Symbolic.GO_UP, IconSize.BUTTON);
                    this.switch_button.sensitive = true;
                    break;
                }
            }
        }

        public HeaderBar() {
            this.switch_button_state = SwitchButtonState.FINDER;

            var header_box = new Box(Orientation.HORIZONTAL, 0);
            {
                this.switch_button = new Button.from_icon_name(IconName.Symbolic.VIEW_LIST, IconSize.BUTTON);
                {
                    this.switch_button.get_style_context().add_class(StyleClass.TITLEBUTTON);
                    this.switch_button.add(new Image.from_icon_name(IconName.Symbolic.VIEW_LIST, IconSize.BUTTON));
                    this.switch_button.clicked.connect(() => {
                        if (this.switch_button_state == SwitchButtonState.FINDER) {
                            this.switch_button_state = SwitchButtonState.PLAYLIST;
                        } else {
                            this.switch_button_state = SwitchButtonState.FINDER;
                        }
                        this.switch_button_clicked(this.switch_button_state);
                    });
                }

                this.add_button = new Button.from_icon_name(IconName.Symbolic.BOOKMARK_NEW, IconSize.BUTTON);
                {
                    this.add_button.get_style_context().add_class(StyleClass.TITLEBUTTON);
                    this.add_button.add(new Image.from_icon_name(IconName.Symbolic.BOOKMARK_NEW, IconSize.BUTTON));
                    this.add_button.tooltip_text = Text.TOOLTIP_SAVE_PLAYLIST;
                    this.add_button.clicked.connect(() => {
                        this.add_button_clicked();
                    });
                }

                header_box.add(this.switch_button);
                header_box.add(this.add_button);
            }

            this.fold_button = new ToggleButton();
            {
                this.fold_button.get_style_context().add_class(StyleClass.TITLEBUTTON);
                this.fold_button.add(new Image.from_icon_name(IconName.Symbolic.GO_UP, IconSize.BUTTON));
                this.fold_button.sensitive = true;
                this.fold_button.active = true;
                this.fold_button.clicked.connect(() => {
                    if (this.fold_button_state == FoldButtonState.OPENED) {
                        this.fold_button_state = FoldButtonState.FOLDED;
                    } else {
                        this.fold_button_state = FoldButtonState.OPENED;
                    }
                    this.fold_button_clicked(this.fold_button_state);
                });
            }

            this.about_button = new Button();
            {
                this.about_button.get_style_context().add_class(StyleClass.TITLEBUTTON);
                this.about_button.add(new Image.from_icon_name(IconName.Symbolic.HELP_ABOUT, IconSize.BUTTON));
                this.about_button.sensitive = true;
                this.about_button.clicked.connect(() => {
                    this.about_button_clicked();
                });
            }

            this.show_close_button = true;
            this.title = PROGRAM_NAME;
            this.has_subtitle = false;
            this.pack_start(header_box);
            this.pack_end(fold_button);
            this.pack_end(about_button);
        }

        public void disable_switch_button() {
            this.switch_button.sensitive = false;
        }

        public void enable_switch_button() {
            this.switch_button.sensitive = true;
        }

        public string? switch_button_icon_name {
            owned get {
                Image? icon = this.switch_button.image as Image;
                if (icon != null) {
                    return icon.icon_name;
                } else {
                    return null;
                }
            }

            set {
                Image? icon = this.switch_button.image as Image;
                if (icon != null) {
                    icon.icon_name = value;
                }
            }
        }

        public void show_add_button() {
            this.add_button.visible = true;
        }

        public void hide_add_button() {
            this.add_button.visible = false;
        }
    }
}
