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
    public class ImageLoaderThreadData {
        private string file_path;
        private int icon_size;
        public Gdk.Pixbuf? icon_pixbuf { get; set; }
        public bool pixbuf_loaded;

        public ImageLoaderThreadData(string file_path, int icon_size) {
            this.file_path = file_path;
            this.icon_size = icon_size;
            this.icon_pixbuf = null;
            this.pixbuf_loaded = false;
        }

        public void* run() {
            debug("thread starts");
            try {
                icon_pixbuf = Files.load_first_artwork(file_path, icon_size);
            } catch (Tatam.Error e) {
                stderr.printf(@"Tatam.Error: $(e.message)\n");
                return null;
            } catch (FileError e) {
                Process.exit(1);
            }
            debug("thread ends %s of %s", (icon_pixbuf != null ? "icon has been loaded" : "icon is null"), file_path);
            pixbuf_loaded = true;
            return icon_pixbuf;
        }
    }
}
