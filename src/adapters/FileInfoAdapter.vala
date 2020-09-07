namespace Tatam {
    public class FileInfoAdapter : Object {
        public async Tatam.FileInfo? read_metadata_from_path(string file_path) {
            GLib.File file = GLib.File.new_for_path(file_path);
            Tatam.FileInfo file_info = new Tatam.FileInfo();
            file_info.dir = file.get_parent().get_path();
            file_info.path = file.get_path();
            file_info.name = file.get_basename();
            file_info.file_type = Tatam.FileType.MUSIC;
            try {
                MetadataReader meta_reader = new Tatam.MetadataReader();
                meta_reader.tag_found.connect((tag, value) => {
                        file_info_set_value(ref file_info, tag, value);
                        return true;
                    });
                yield meta_reader.get_metadata(file_path);
            } catch (Tatam.Error e) {
                stderr.printf(@"Tatam.Error: $(e.message)\n");
            } catch (GLib.Error e) {
                stderr.printf(@"GLib.Error: $(e.message)\n");
            }
            return file_info;
        }
        
        private void file_info_set_value(ref Tatam.FileInfo file_info, string tag, Value? value) {
            string tag_lower = tag.down();
            debug(@"Tag: $(tag)");
            switch (tag_lower) {

            case "title":
                file_info.title = value.get_string();
                break;

            case "artist":
            case "album-artist":
            case "composer":
                file_info.artist = value.get_string();
                break;

            case "album":
                file_info.album = value.get_string();
                break;

            case "datetime":
                Gst.DateTime datetime = (Gst.DateTime) value.get_boxed();
                file_info.date = datetime.get_year();
                break;

            case "comment":
                file_info.comment = value.get_string();
                break;

            case "track":
            case "track-number":
                file_info.track = value.get_uint();
                break;

            case "genre":
                file_info.genre = value.get_string();
                break;

            case "track-count":
                file_info.track_count = value.get_uint();
                break;

            case "disc-count":
            case "album-disc-count":
                file_info.disc_count = value.get_uint();
                break;

            case "disc":
            case "disc-number":
            case "album-disc-number":
                file_info.disc_number = value.get_uint();
                break;

            case "duration":
                file_info.time_length = (Tatam.SmallTime) value.get_object();
                break;

            case "image":
                try {
                    Gst.Sample sample = (Gst.Sample) value.get_boxed();
                    Gst.Buffer? buffer = sample.get_buffer();
                    if (buffer == null) {
                        return;
                    }
                    
                    debug("buffer ok");
                    size_t size_1 = buffer.get_size();
                    if (size_1 == 0) {
                        return;
                    }
                    
                    debug("size ok");
                    uint8[] data;
                    buffer.extract_dup(0, size_1, out data);
                    if (size_1 == 0) {
                        return;
                    }
                    
                    debug("extract ok");
                    string file_name = "/home/ta/Work/tatam/tmp/image";
                    GLib.File image_file = GLib.File.new_for_path(file_name);
                    FileOutputStream output;

                    if (image_file.query_exists()) {
                        output = image_file.replace(null, false, 0, null);
                    } else {
                        GLib.File dir = GLib.File.new_for_path("/home/ta/Work/tatam/tmp");
                        if (!dir.query_exists()) {
                            dir.make_directory();
                        }
                        output = image_file.create(0, null);
                    }

                    output.write(data, null);
                    debug("write ok");
                    Gdk.Pixbuf? pixbuf = new Gdk.Pixbuf.from_file(file_name);
                    if (pixbuf != null) {
                        debug("pixbuf ok");
                        file_info.artwork = pixbuf;
                    }
                } catch (GLib.Error e) {
                    stderr.printf(@"GLib.Error: $(e.message)\n");
                }
                break;
            }
        }
    }
}
