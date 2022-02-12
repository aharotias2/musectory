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
 * Copyright 2020 Takayuki Tanaka
 */

namespace Musectory {
    [Flags]
    public enum FileType {
        DIRECTORY,
        DISC,
        FILE,
        MUSIC,
        UNKNOWN,
        ALL;
        public string get_name() {
            switch (this) {
              case DIRECTORY: return "DIRECTORY";
              case DISC: return "DISC";
              case FILE: return "FILE";
              case MUSIC: return "MUSIC";
              case UNKNOWN: return "UNKNOWN";
              case ALL: default: return "ALL";
            }
        }
    }

    public enum MenuType {
        BOOKMARK,
        FOLDER,
        PLAYLIST_HEADER,
        PLAYLIST_NAME,
        CHOOSER,
        REMOVE,
        MOVE_UP,
        MOVE_DOWN,
        SEPARATOR
    }

    public enum ControllerState {
        PLAY, PAUSE, FINISHED
    }
}