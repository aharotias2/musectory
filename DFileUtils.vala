/*
 * This file is part of dplayer.
 * 
 *     dplayer is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 * 
 *     dplayer is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 * 
 *     You should have received a copy of the GNU General Public License
 *     along with dplayer.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright 2018 Takayuki Tanaka
 */

namespace DPlayer {
    class DFileUtils : Object {
        public string dir_path { get; set; }
        public CompareFunc<DFileInfo?> file_compare_func;

        public DFileUtils(string dir_path) {
            this.dir_path = dir_path;
            file_compare_func = (a, b) => {
                return a.name.collate(b.name);
            };
        }

        public DFileType determine_file_type() throws FileError {
            DFileType answer = DFileType.UNKNOWN;
            GLib.Dir dir;

            if (FileUtils.test(dir_path, FileTest.IS_REGULAR)) {
                return DFileType.FILE;
            }

            if (dir_path.slice(dir_path.last_index_of_char('/'), dir_path.length) == "/..") {
                return DFileType.PARENT;
            }

            try {
                dir = Dir.open(dir_path, 0);
            } catch (FileError e) {
                stderr.printf("FileError at determin_file_type: cannot open directory %s.\n", dir_path);
                throw e;
            }

            string? name = null;

            while ((name = dir.read_name()) != null) {
                string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, name);

                if (FileUtils.test(path, FileTest.IS_DIR)) {
                    return DFileType.DIRECTORY;
                } else {
                    answer = DFileType.DISC;
                }
            }
            return answer;
        }

        public void find_dir_file_names(ref List<string> dir_list, ref List<string> file_list) {
            Dir dir;

            try {
                dir = Dir.open(dir_path, 0);
            } catch (FileError e) {
                return;
            }

            string name = null;

            while ((name = dir.read_name()) != null) {
                string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, name);
                if (FileUtils.test(path, FileTest.IS_DIR)) {
                    dir_list.insert_sorted(path.dup(), (a, b) => { return a.collate(b); });
                } else if (FileUtils.test(path, FileTest.IS_REGULAR)) {
                    file_list.insert_sorted(path.dup(), (a, b) => { return a.collate(b); });
                }
            }
        }

        public void find_dir_files(ref List<string> dir_list, ref List<DFileInfo?> file_list) throws FileError {
            Dir dir;

            if (!FileUtils.test(dir_path, FileTest.IS_DIR)) {
                return;
            }

            try {
                dir = Dir.open(dir_path, 0);
            } catch (FileError e) {
                stderr.printf("FileError at find_dir_files: cannot open directory %s.\n", dir_path);
                throw e;
            }

            string? name = null;
            dir_list = new List<string>();
            file_list = new List<DFileInfo?>();

            while ((name = dir.read_name()) != null) {
                string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, name);

                if (FileUtils.test(path, FileTest.IS_DIR)) {
                    dir_list.insert_sorted(name, (a, b) => { return a.collate(b); });
                } else {
                    var file_info = new DFileInfo();
                    if (MPlayer.get_file_info(path, ref file_info)) {
                        file_list.insert_sorted(file_info, file_compare_func);
                    }
                }
            }
        }

        public List<string> find_file_names_recursively() {
            var dir_list = new List<string>();
            var file_list = new List<string>();
            find_dir_file_names(ref dir_list, ref file_list);
            foreach (string subdir_path in dir_list) {
                file_list.concat(new DFileUtils(subdir_path).find_file_names_recursively());
            }
            return file_list;
        }

        public List<DFileInfo?>? get_file_info_and_artwork_list_in_dir() {
            if (!FileUtils.test(dir_path, FileTest.IS_DIR)) {
                return null;
            }

            List<DFileInfo?> info_list = new List<DFileInfo?>();
            List<string> dir_list = new List<string>();
            List<string> file_list = new List<string>();
            find_dir_file_names(ref dir_list, ref file_list);

            info_list.append(make_parent_file_info());

            foreach (string subdir_path in dir_list) {
                info_list.append(make_subdir_info(subdir_path));
            }

            info_list.concat(MPlayer.get_file_info_and_artwork_list_from_file_list(file_list));
            return info_list;
        }


        public List<DFileInfo?> find_file_infos_recursively() throws FileError {
            if (!FileUtils.test(dir_path, FileTest.IS_DIR)) {
                return new List<DFileInfo?>();
            }

            var file_list = find_file_names_recursively();
            return MPlayer.get_file_info_and_artwork_list_from_file_list(file_list);
        }

        public Gdk.Pixbuf? load_first_artwork(int size) throws FileError {
            Dir dir;
            string dir_artwork_path = create_dir_artwork_path("");
            if (FileUtils.test(dir_path, FileTest.IS_DIR)) {
                if (FileUtils.test(dir_artwork_path, FileTest.EXISTS)) {
                    debug("dir artwork file exists: " + dir_artwork_path);
                    return MPlayer.get_music_artwork(dir_artwork_path, size);
                }

                try {
                    dir = Dir.open(dir_path, 0);
                } catch (FileError e) {
                    stderr.printf("FileError at load_first_artwork: cannot open directory %s.\n", dir_path);
                    throw e;
                }

                string? name = null;

                while ((name = dir.read_name()) != null) {
                    string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, name);

                    if (FileUtils.test(path, FileTest.IS_REGULAR)) {
                        if (MPlayer.is_music_file(path)) {
                            debug("load_first_artwork: found a file: " + path);
                            string pic_file_path_temp = MPlayer.create_artwork_file(path);
                            debug("first artwork in dir: " + pic_file_path_temp);
                            string ext = extension(pic_file_path_temp);
                            debug("extension: " + ext);
                            FileUtils.rename(pic_file_path_temp, dir_artwork_path + ext);
                            debug("renamed to: " + dir_artwork_path + ext);
                            return MPlayer.get_music_artwork(dir_artwork_path, size);
                        }
                    }
                }
            }
            return null;
        }

        public string extension(string file_path) {
            return file_path.substring(file_path.last_index_of_char('.') + 1, file_path.length);
        }
        
        public string create_dir_artwork_path(string extension) {
            string dirname = Path.get_basename(Path.get_dirname(dir_path));
            string basename = Path.get_basename(dir_path);
            return "/tmp/" + program_name + "/" + dirname + "_" + basename + (extension != "" ? "." + extension : "");
        }
        
        public bool contains_music(int max_depth = 0, int depth = 0) throws FileError {
            Dir dir;

            try {
                dir = Dir.open(dir_path, 0);
            } catch (FileError e) {
                stderr.printf("FileError at contains_music: cannot open directory %s\n", dir_path);
                throw e;
            }

            string? name = null;

            debug("search into " + dir_path + ". max_depth = " + max_depth.to_string() + ", depth = " + depth.to_string());
            
            while ((name = dir.read_name()) != null) {
                string path = Path.build_path(Path.DIR_SEPARATOR_S, dir_path, name);

                if (FileUtils.test(path, FileTest.IS_DIR)) {
                    debug("contains_music: dir: " + path);
                    if (depth < max_depth) {
                        if (new DFileUtils(path).contains_music(max_depth, depth + 1)) {
                            return true;
                        }
                    }
                } else {
                    debug("contains_music: file" + path);
                    DFileInfo file_info = new DFileInfo();
                    if (MPlayer.get_file_info(path, ref file_info)) {
                        return true;
                    }
                }
            }
            debug("contains_music end");
            return false;
        }

        public DFileInfo make_parent_file_info() {
            DFileInfo parent = new DFileInfo();
            parent.path = Path.get_dirname(dir_path);
            parent.name = "..";
            parent.file_type = DFileType.PARENT;
            return parent;
        }

        public DFileInfo make_subdir_info(string subdir_path) {
            DFileInfo info = new DFileInfo();
            info.dir = dir_path.dup();
            info.path = subdir_path.dup();
            info.name = Path.get_basename(subdir_path);
            info.file_type = DFileType.DIRECTORY;
            return info;
        }
    }
}

