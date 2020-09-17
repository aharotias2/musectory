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
    public struct Options {
        public int icon_size;
        public int thumbnail_size;
        public ShowThumbsAt show_thumbs_at;
        public int playlist_image_size;
        public string? last_playlist_name;
        public bool play_style;
    }
}
