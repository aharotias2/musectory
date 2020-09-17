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

using Gdk;

namespace Tatam {
    public class FileUtils {
        public static int compare_mtime(string file1_path, string file2_path) {
            return TimeUtils.compare(get_file_mtime(file1_path), get_file_mtime(file2_path));
        }

        public static Time get_file_mtime(string file_path) {
            Posix.Stat file_status;
            Posix.stat(file_path, out file_status);
            return Time.local(file_status.st_mtime);
        }

        public static bool is_empty(string file_path) {
            Posix.Stat file_status;
            Posix.stat(file_path, out file_status);
            return ((uint) file_status.st_size) == 0;
        }

        public static void create_empty_file(string file_path) throws Error, IOError {
            if (!GLib.FileUtils.test(file_path, FileTest.EXISTS)) {
                File f = File.new_for_path(file_path);
                var stream = f.create(FileCreateFlags.NONE);
                stream.close();
            }
        }
    }
}

