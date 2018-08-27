using Gtk;
namespace DPlayer {
    class ArtworkView : Bin {
        public signal void activate();
        public signal void deactivate();
        public signal void fit_to_window();
        public int width { get { return get_allocated_width(); } }
        public int height { get { return get_allocated_height(); } }
        private ScrolledWindow container;
        private Image artwork;
        private Gdk.Pixbuf pixbuf;
        public ArtworkView() {
            Overlay overlay = new Overlay();
            {
                var close_button = new Button.from_icon_name(IconName.Symbolic.WINDOW_CLOSE, IconSize.BUTTON);
                {
                    close_button.halign = Align.END;
                    close_button.valign = Align.START;
                    close_button.margin = 10;
                    close_button.clicked.connect(() => {
                            deactivate();
                        });
                }

                container = new ScrolledWindow(null, null);
                {
                    artwork = new Image();
                    {
                        artwork.margin = 0;
                    }
                    container.add(artwork);
                    container.get_style_context().add_class(StyleClass.ARTWORK_BACKGROUND);
                }

                overlay.add(container);
                overlay.add_overlay(close_button);
                overlay.set_overlay_pass_through(close_button, true);
            }
        
            activate.connect(() => {
                    visible = true;
                    Timeout.add(100, () => {
                            fit_to_window();
                            return Source.REMOVE;
                        });
                });

            deactivate.connect(() => {
                    visible = false;
                });

            fit_to_window.connect(() => {
                    if (visible) {
                        Timeout.add(100, () => {
                                int size = int.min(width, height);
                                artwork.pixbuf = MyUtils.PixbufUtils.scale_limited(pixbuf, size);
                                return Source.REMOVE;
                            });
                    }
                });

            add(overlay);
            show_all();
        }

        public void set_artwork_pixbuf(Gdk.Pixbuf pixbuf) {
            this.pixbuf = pixbuf;
            fit_to_window();
        }
   }
}