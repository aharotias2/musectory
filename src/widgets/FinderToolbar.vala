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
    public class FinderToolbar : Bin {
        private Button finder_parent_button;
        private Button finder_zoomin_button;
        private Button finder_zoomout_button;
        private Entry finder_location;
        private Button finder_refresh_button;
        private Button finder_add_button;

        public signal void parent_button_clicked();
        public signal void zoomin_button_clicked();
        public signal void zoomout_button_clicked();
        public signal void location_entered(string location);
        public signal void refresh_button_clicked();
        public signal void add_button_clicked();

        public FinderToolbar() {
            var box = new Box(Orientation.HORIZONTAL, 4);
            {
                finder_parent_button = new Button.from_icon_name(IconName.Symbolic.GO_UP, IconSize.BUTTON);
                {
                    finder_parent_button.tooltip_text = _("Go up");
                    finder_parent_button.clicked.connect(() => {
                        parent_button_clicked();
                    });
                }

                var finder_zoom_box = new Box(Orientation.HORIZONTAL, 0);
                {
                    finder_zoomin_button = new Button.from_icon_name(IconName.Symbolic.ZOOM_IN,
                                                                     IconSize.BUTTON);
                    {
                        finder_zoomin_button.get_style_context().add_class(StyleClass.TITLEBUTTON);
                        finder_zoomin_button.tooltip_text = _("Zoom in");
                        finder_zoomin_button.clicked.connect(() => {
                            zoomin_button_clicked();
                        });
                    }

                    finder_zoomout_button = new Button.from_icon_name(IconName.Symbolic.ZOOM_OUT,
                                                                      IconSize.BUTTON);
                    {
                        finder_zoomout_button.get_style_context().add_class(StyleClass.TITLEBUTTON);
                        finder_zoomout_button.tooltip_text = _("Zoom out");
                        finder_zoomout_button.clicked.connect(() => {
                            zoomout_button_clicked();
                        });
                    }

                    finder_zoom_box.pack_start(finder_zoomin_button, false, false);
                    finder_zoom_box.pack_start(finder_zoomout_button, false, false);
                }

                finder_location = new Entry();
                {
                    finder_location.activate.connect(() => {
                        location_entered(finder_location.get_text());
                    });
                }

                finder_refresh_button = new Button.from_icon_name(IconName.Symbolic.VIEW_REFRESH,
                                                                  IconSize.BUTTON);
                {
                    finder_refresh_button.get_style_context().add_class(StyleClass.TITLEBUTTON);
                    finder_refresh_button.tooltip_text = _("Reload");
                    finder_refresh_button.clicked.connect(() => {
                        refresh_button_clicked();
                    });
                }

                finder_add_button = new Button.from_icon_name(IconName.Symbolic.BOOKMARK_NEW,
                                                              IconSize.BUTTON);
                {
                    finder_add_button.get_style_context().add_class(StyleClass.TITLEBUTTON);
                    finder_add_button.tooltip_text = _("Bookmark this directory");
                    finder_add_button.clicked.connect(() => {
                        add_button_clicked();
                    });
                }

                box.pack_start(finder_parent_button, false, false);
                box.pack_start(finder_zoom_box, false, false);
                box.pack_start(finder_location, true, true);
                box.pack_start(finder_refresh_button, false, false);
                box.pack_start(finder_add_button, false, false);
            }

            add(box);
        }

        public void deactivate_buttons() {
            finder_add_button.sensitive = false;
            finder_zoomout_button.sensitive = false;
            finder_zoomin_button.sensitive = false;
        }

        public void activate_buttons() {
            finder_add_button.sensitive = true;
            finder_zoomout_button.sensitive = true;
            finder_zoomin_button.sensitive = true;
        }
    }
}
