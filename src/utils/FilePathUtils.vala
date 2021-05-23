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
 * Copyright 2018 Takayuki Tanaka
 */

namespace Moegi.FilePathUtils {
    public string extension_of(string file_path) {
        return file_path.slice(file_path.last_index_of(".") + 1, file_path.length);
    }

    public string remove_extension(string file_path) {
        return file_path.slice(0, file_path.last_index_of("."));
    }

    public string make_cache_path(string file_path) {
        string result = "/tmp/" + Moegi.PROGRAM_NAME + "/cache";
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

