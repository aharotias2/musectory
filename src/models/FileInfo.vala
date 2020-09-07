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
    public class FileInfo : Object {
        public string dir;
        public string name;
        public string path;
        public string title;
        public string artist;
        public string album;
        public string genre;
        public string comment;
        public string copyright;
        public uint disc_number;
        public uint disc_count;
        public uint track;
        public uint track_count;
        public uint date;
        public SmallTime time_length;
        public Tatam.FileType file_type;
        public Gdk.Pixbuf artwork;

        public FileInfo copy() {
            Tatam.FileInfo cp = new Tatam.FileInfo();
            cp.dir = this.dir;
            cp.name = this.name;
            cp.path = this.path;
            cp.title = this.title;
            cp.artist = this.artist;
            cp.album = this.album;
            cp.genre = this.genre;
            cp.comment = this.comment;
            cp.copyright = this.copyright;
            cp.disc_number = this.disc_number;
            cp.disc_count = this.disc_count;
            cp.track = this.track;
            cp.track_count = this.track_count;
            cp.date = this.date;
            cp.time_length = this.time_length;
            cp.file_type = this.file_type;
            cp.artwork = this.artwork;
            return cp;
        }

        public string to_string() {
            string empty = "(null)";
            return @"{ \"dir\" : \"$(dir != null ? dir : empty)\", \"name\" : \"$(name != null ? name : empty)\", \"path\" : \"$(path != null ? path : empty)\", \"title\" : \"$(title != null ? title : empty)\", \"artist\" : \"$(artist != null ? artist : empty)\", \"album\" : \"$(album != null ? album : empty)\", \"genre\" : \"$(genre != null ? genre : empty)\", \"comment\" : \"$(comment != null ? comment : empty)\", \"copyright\" : \"$(copyright != null ? copyright : empty)\", \"disc_number\" : $(disc_number), \"disc_count\" : $(disc_count), \"track\" : $(track), \"track_count\" : $(track), \"date\" : $(date), \"time_length\" : \"$(time_length.to_string())\", \"file_type\" : \"$(file_type.get_name())\" }";
        }
    }
}
