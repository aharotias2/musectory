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
 * Copyright 2018 Takayuki Tanaka
 */

namespace Tatam {
    public class FilePathUtils {
        public static string extension_of(string file_path) {
            return file_path.slice(file_path.last_index_of(".") + 1, file_path.length);
        }

        public static string remove_extension(string file_path) {
            return file_path.slice(0, file_path.last_index_of("."));
        }

        public static string make_cache_path(string file_path) {
            string result = "/tmp/" + Tatam.PROGRAM_NAME + "/cache";
            File file = File.new_for_path(file_path);
            GLib.FileType type = file.query_file_type(0);
            if (type == GLib.FileType.DIRECTORY) {
                result += file_path + "/dirImage";
            } else {
                result += file_path + "_image";
            }
            return result;
        }
    }
}

