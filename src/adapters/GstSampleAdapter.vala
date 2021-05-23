/*
 * This file is part of moegi-player.
 *
 *     moegi-player is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     moegi-player is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with moegi-player.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright 2020 Takayuki Tanaka
 */

namespace Moegi {
    public class GstSampleAdapter : Object {
        public Gdk.Pixbuf? read_pixbuf_from_audio_path(string file_path) {
            Gdk.Pixbuf? pixbuf = null;
            try {
                MetadataReader meta_reader = new Moegi.MetadataReader();
                meta_reader.tag_found.connect((tag, value) => {
                    if (tag == "image") {
                        Gst.Sample? sample = (Gst.Sample?)value.get_boxed();
                        if (sample != null) {
                            pixbuf = extract_pixbuf_from_gst_sample(sample, file_path);
                        }
                        return false;
                    }
                    return true;
                });
                meta_reader.get_metadata(file_path);
            } catch (Moegi.Error e) {
                stderr.printf(@"Moegi.Error: $(e.message)\n");
            } catch (GLib.Error e) {
                stderr.printf(@"GLib.Error: $(e.message)\n");
            }
            return pixbuf;
        }

        public Gdk.Pixbuf? extract_pixbuf_from_gst_sample(Gst.Sample sample, string file_path) {
            string cache_file_path = FilePathUtils.make_cache_path(file_path);
            File cache = File.new_for_path(cache_file_path);

            if (!cache.query_exists()) {
                Gst.Buffer? buffer = sample.get_buffer();
                if (buffer == null) {
                    return null;
                }

                debug("buffer ok");
                size_t size_1 = buffer.get_size();
                if (size_1 == 0) {
                    return null;
                }

                debug("size ok");
                uint8[] data;
                buffer.extract_dup(0, size_1, out data);
                if (size_1 == 0) {
                    return null;
                }
                debug("extract ok");
                save_buffer(cache_file_path, data);
            }

            try {
                Gdk.Pixbuf? pixbuf = new Gdk.Pixbuf.from_file(cache_file_path);
                if (pixbuf != null) {
                    debug("pixbuf ok");
                    return pixbuf;
                }
            } catch (GLib.Error e) {
                stderr.printf(@"Error: $(e.message)\n");
            }
            return null;
        }

        private void save_buffer(string file_path, uint8[] data) {
            try {
                GLib.File image_file = GLib.File.new_for_path(file_path);
                FileOutputStream output;
                if (image_file.query_exists()) {
                    image_file.delete();
                }
                GLib.File dir = image_file.get_parent();
                if (!dir.query_exists()) {
                    DirUtils.create_with_parents(dir.get_path(), 0755);
                }
                output = image_file.create(0, null);
                output.write(data, null);
                debug("write ok");
            } catch (GLib.IOError e) {
                stderr.printf(@"IOError: $(e.message)\n");
            } catch (GLib.Error e) {
                stderr.printf(@"Error: $(e.message)\n");
            }
        }
    }
}
