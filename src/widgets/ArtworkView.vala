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
    public interface ArtworkViewInterface {
        public signal void close_button_clicked();
        public abstract Gdk.Pixbuf? artwork { get; set; }
        public abstract void fit_image();
        public abstract void set_image_from_icon_name(string icon_name);
    }

    public class ArtworkView : Bin, ArtworkViewInterface {
        private Overlay artwork_view_overlay;
        private Button close_button;
        private ScrolledWindow artwork_container;
        private Image artwork_image;
        public Gdk.Pixbuf? artwork { get; set; }
        
        public ArtworkView() {
            artwork_view_overlay = new Overlay();
            {
                close_button = new Button.from_icon_name(IconName.Symbolic.WINDOW_CLOSE, IconSize.BUTTON);
                {
                    close_button.halign = Align.END;
                    close_button.valign = Align.START;
                    close_button.margin = 10;
                    close_button.clicked.connect(() => {
                            close_button_clicked();
                        });
                }

                artwork_container = new ScrolledWindow(null, null);
                {
                    artwork_container.get_style_context().add_class(StyleClass.ARTWORK_BACKGROUND);
                }

                artwork_image = new Image();
                {
                    artwork_image.margin = 0;
                    artwork_container.add(artwork_image);
                }

                artwork_view_overlay.add(artwork_container);
                artwork_view_overlay.add_overlay(close_button);
                artwork_view_overlay.set_overlay_pass_through(close_button, true);
            }

            add(artwork_view_overlay);
        }

        public void fit_image() {
            if (artwork != null) {
                int width = artwork_container.get_allocated_width();
                int height = artwork_container.get_allocated_height();
                artwork_image.pixbuf = PixbufUtils.scale(artwork, int.min(width, height));
            }
        }

        public void set_image_from_icon_name(string icon_name) {
            artwork_image.set_from_icon_name(icon_name, IconSize.LARGE_TOOLBAR);
        }
    }
}
