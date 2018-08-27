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
    public class DFileInfo : Object {
        public string dir { get; set; }
        public string name { get; set; }
        public string path { get; set; }
        public string album { get; set; }
        public string artist { get; set; }
        public string comment { get; set; }
        public string genre { get; set; }
        public string title { get; set; }
        public string track { get; set; }
        public string disc { get; set; }
        public string date { get; set; }
        public string time_length { get; set; }
        public DFileType file_type { get; set; }
        public Gdk.Pixbuf artwork { get; set; }

        public DFileInfo copy() {
            DFileInfo dest = new DFileInfo();
            dest.path = path.dup();
            dest.name = name.dup();
            dest.dir = dir.dup();
            dest.album = album.dup();
            dest.artist = artist.dup();
            dest.comment = comment.dup();
            dest.genre = genre.dup();
            dest.title = title.dup();
            dest.track = track.dup();
            dest.disc = disc.dup();
            dest.date = date.dup();
            dest.time_length = time_length.dup();
            dest.file_type = file_type;
            if (artwork != null) {
                dest.artwork = artwork.copy();
            }
            return (owned) dest;
        }
    }
}
