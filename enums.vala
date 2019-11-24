/*
 * This file is part of mpd.
 * 
 *     mpd is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 * 
 *     mpd is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 * 
 *     You should have received a copy of the GNU General Public License
 *     along with mpd.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright 2018 Takayuki Tanaka
 */

namespace Mpd {

    [Flags]
    public enum DFileType {
        DIRECTORY,
        DISC,
        FILE,
        PARENT,
        UNKNOWN,
        ALL
    }

    public enum MusicViewIconType {
        STOPPED,
        PAUSED,
        PLAYING
    }

    public enum MenuType {
        BOOKMARK,
        FOLDER,
        FINDER,
        PLAYLIST_HEADER,
        PLAYLIST_NAME,
        CHOOSER,
        CONFIG,
        ABOUT,
        QUIT,
        REMOVE,
        MOVE_UP,
        MOVE_DOWN,
        SEPARATOR
    }

    public enum DnDTarget {
        STRING
    }

    public enum Column {
        TITLE,
        LENGTH,
        ALBUM,
        ARTIST,
        COMPOSER,
        GENRE,
        TRACK,
        DISC,
        DATE,
        COMMENT
    }

    public enum SaveMode {
        OVERWRITE,
        CREATE
    }
    
/* オプション用のデータ型 */
    public enum FinderLayout {
        GRID,
        LIST
    }

    public enum ShowThumbsAt {
        ALBUMS,
        FILES
    }

}