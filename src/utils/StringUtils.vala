/*
 * This file is part of musectory-player.
 *
 *     musectory-player is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     musectory-player is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with musectory-player.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright 2018 Takayuki Tanaka
 */

using Gdk;

extern int musectory_filename_compare(string str_a, string str_b);

namespace Musectory.StringUtils {
    public Gee.List<string> array_to_list(string[] array) {
        Gee.List<string> list = new Gee.ArrayList<string>();
        foreach (string item in array) {
            list.add(item);
        }
        return list;
    }

    public int compare_filenames(string str_a, string str_b) {
        return musectory_filename_compare(str_a, str_b);
    }
}

