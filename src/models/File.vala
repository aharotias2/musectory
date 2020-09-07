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

namespace Tatam {
    public class File {
        private string path;
        private Tatam.FileType type;
        private GLib.File internal_file;
        private GLib.FileType g_file_type;
        private GLib.FileInfo g_file_info;
        private string extension_value;

        public string extension {
            private set {
                extension_value = value;
            }
            
            get {
                if (extension_value == null) {
                    extension_value =  get_extension();
                }
                return extension_value;
            }
        }
        
        public File.new_for_path(string path) throws GLib.Error {
            this.path = path;
            this.type = Tatam.FileType.UNKNOWN;
            this.internal_file = GLib.File.new_for_path(path);
            this.g_file_info = internal_file.query_info("standard::*", 0);
            this.g_file_type = g_file_info.get_file_type();
        }

        public Tatam.FileType get_file_type(bool recursive = true) throws FileError {
            if (type != Tatam.FileType.UNKNOWN) {
                return type;
            }

            if (g_file_type == GLib.FileType.REGULAR) {
                string mime_type = g_file_info.get_content_type();
                if (mime_type.has_prefix("audio")) {
                    type = Tatam.FileType.MUSIC;
                } else {
                    type = Tatam.FileType.FILE;
                }
                return type;
            }

            if (g_file_type != GLib.FileType.DIRECTORY) {
                type = Tatam.FileType.UNKNOWN;
                return type;
            }
                
            type = Tatam.FileType.DIRECTORY;
            if (!recursive) {
                return type;
            }

            DirectoryReader dir_reader = new DirectoryReader(this.path);
            dir_reader.file_found.connect((file) => {
                    Tatam.File child = new Tatam.File.new_for_path(file.get_path());
                    if (child.get_file_type(false) == Tatam.FileType.MUSIC) {
                        type = Tatam.FileType.DISC;
                        return false;
                    }
                    return true;
                });
            dir_reader.run();
            return type;
        }

        public void get_dir_file_names(out List<string> dir_list, out List<string> file_list) throws FileError {
            if (type != Tatam.FileType.DISC && type != Tatam.FileType.DIRECTORY) {
                return;
            }

            try {
                dir_list = new GLib.List<string>();
                file_list = new GLib.List<string>();
                DirectoryReader dir_reader = new DirectoryReader(this.path);
                dir_reader.dir_found.connect((dir) => {
                        dir_list.insert_sorted(path.dup(), (a, b) => { return a.collate(b); });
                    });
                dir_reader.file_found.connect((file) => {
                        GLib.FileInfo fi = file.query_info("standard::*", 0);
                        if (fi.get_content_type().has_prefix("audio")) {
                            file_list.insert_sorted(path.dup(), (a, b) => { return a.collate(b); });
                        }
                    });
                dir_reader.run();
            } catch (FileError e) {
                throw e;
            }
        }

        public void find_dir_files(out List<string> dir_list, out List<Tatam.FileInfo?> file_list) throws FileError {
            if (type != Tatam.FileType.DISC && type != Tatam.FileType.DIRECTORY) {
                return;
            }

            try {
                dir_list = new GLib.List<string>();
                file_list = new GLib.List<Tatam.FileInfo?>();
                DirectoryReader dir_reader = new DirectoryReader(this.path);
                dir_reader.dir_found((dir) => {
                        dir_list.insert_sorted(name, (a, b) => { return a.collate(b); });
                        return true;
                    });
                dir_reader.file_found((file) => {
                        FileInfo fi = file.query_info("standard::*", 0);
                        if (fi.get_content_type().has_prefix("audio")) {
                            var file_info = new Tatam.FileInfo();
                            if (MPlayer.get_file_info(path, ref file_info)) {
                                file_list.insert_sorted(file_info, file_compare_func);
                            }
                        }
                        return true;
                    });
                dir_reader.run();
            } catch (FileError e) {
                stderr.printf("FileError at find_dir_files: cannot open directory %s.\n", path);
                throw e;
            }
        }

        public GLib.List<string> find_file_names_recursively() {
            GLib.List<string> dir_list;
            GLib.List<string> file_list;
            find_dir_file_names(out dir_list, out file_list);
            foreach (string subdir_path in dir_list) {
                file_list.concat(new Tatam.File(subdir_path).find_file_names_recursively());
            }
            return file_list;
        }

        public string get_extension() {
            return path.substring(path.last_index_of_char('.') + 1, path.length);
        }

        public List<Tatam.FileInfo?>? get_file_info_and_artwork_list_in_dir() {
            if (type != Tatam.FileType.DISC && type != Tatam.FileType.DIRECTORY) {
                return;
            }

            List<Tatam.FileInfo?> info_list = new List<Tatam.FileInfo?>();
            List<string> dir_list;
            List<string> file_list;
            find_dir_file_names(out dir_list, out file_list);

            foreach (string subdir_path in dir_list) {
                info_list.append(make_subdir_info(subdir_path));
            }

            info_list.concat(MPlayer.get_file_info_and_artwork_list_from_file_list(file_list));
            return info_list;
        }

        public Gdk.Pixbuf? load_first_artwork(int size) throws FileError {
            if (type != Tatam.FileType.DISC) {
                return null;
            }

            string dir_artwork_path = create_dir_artwork_path("");
            DirectoryReader dir_reader = new DirectoryReader(this.path);
            if (GLib.FileUtils.test(dir_artwork_path, FileTest.EXISTS)) {
                debug("dir artwork file exists: " + dir_artwork_path);
                return MPlayer.get_music_artwork(dir_artwork_path, size);
            }

            Gdk.Pixbuf? pixbuf = null;
            dir_reader.file_found((file) => {
                    string mime_type = fi.get_content_type();
                    if (mime_type.has_prefix("audio")) {
                        debug("load_first_artwork: found a file: " + path);
                        string pic_file_path_temp = MPlayer.create_artwork_file(path);
                        debug("first artwork in dir: " + pic_file_path_temp);
                        string ext = extension(pic_file_path_temp);
                        debug("extension: " + ext);
                        FileUtils.rename(pic_file_path_temp, dir_artwork_path + ext);
                        debug("renamed to: " + dir_artwork_path + ext);
                        pixbuf = MPlayer.get_music_artwork(dir_artwork_path, size);
                    }
                });
            dir_reader.run();
            return pixbuf;
        }

        public string create_dir_artwork_path() {
            string dirname = Path.get_basename(Path.get_dirname(this.path));
            string basename = Path.get_basename(this.path);
            return "/tmp/" + PROGRAM_NAME + "/" + dirname + "_" + basename;
        }
        
        public Tatam.FileInfo make_parent_file_info() {
            Tatam.FileInfo parent = new Tatam.FileInfo();
            parent.path = Path.get_dirname(dir_path);
            parent.name = "..";
            parent.file_type = Tatam.FileType.PARENT;
            return parent;
        }

        public Tatam.FileInfo make_subdir_info(string subdir_path) {
            Tatam.FileInfo info = new Tatam.FileInfo();
            info.dir = dir_path.dup();
            info.path = subdir_path.dup();
            info.name = Path.get_basename(subdir_path);
            info.file_type = Tatam.FileType.DIRECTORY;
            return info;
        }
    }
}
