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
    namespace Text {
        public const string EMPTY = "";
        public const string PROGRAM_NAME = "musectory-player";
        public const string DESCRIPTION = "フォルダで音楽を管理する人のためのプレイヤ";
        public const string COPYRIGHT = "Ⓒ 2017 Tanaka Takayuki";
        public const string SETTINGS = " settings";
        public const string DIALOG_OK = "_OK";
        public const string DIALOG_CANCEL = "_Cancel";
        public const string DIALOG_OPEN = "_Open";
        public const string FONT_FAMILY = "sans-serif";
        public const string CONFIG_DIALOG_HEADER_AUDIO = "Select the sound system";
        public const string CONFIG_DIALOG_HEADER_THUMBS = "the size of thumbnails";
        public const string CONFIG_DIALOG_HEADER_PLAYLIST_IMAGE = "the size of playlist's image";
        public const string CONFIG_DIALOG_PLAY_STYLE = "Play all files when one file was selected?";
        public const string DIALOG_YES = "Yes";
        public const string DIALOG_NO = "No";
        public const string DIALOG_OPEN_FILE = "Open File";
        public const string PLAYLIST_SAVE_NAME = "Enter new playlist name:";
        public const string CONFIRM_OVERWRITE = "A playlist %s exists. Do you overwrite it?";
        public const string CONFIRM_REMOVE_BOOKMARK = "Do you really remove this bookmark?";
        public const string CONFIRM_REMOVE_PLAYLIST = "Do you really remove this playlist?";
        public const string ALERT_FAIL_TO_DELETE_FILE = "Failed to delete a file (%s)";
        public const string DIR_NAME_MUSIC = "Music";
        public const string MENU_CONFIG = "Config...";
        public const string MENU_ABOUT = "About...";
        public const string MENU_QUIT = "Quit";
        public const string MENU_BOOKMARK = "Bookmark";
        public const string MENU_PLAYLIST = "Playlist";
        public const string MENU_CHOOSE_DIR = "Choose directory...";
        public const string MENU_REMOVE_ITEM = "Remove this item";
        public const string MENU_MOVE_UP = "Move this item up";
        public const string MENU_MOVE_DOWN = "Move this item down";
        public const string MARKUP_BOLD_ITALIC = "<b><i>%s</i></b>";
        public const string FINDER_LOAD_FILES = "Loading data from disk...";
        public const string FILE_LOADED = "%s is loaded";
        public const string TOOLTIP_SHOW_FINDER = "Show finder";
        public const string TOOLTIP_SHOW_PLAYLIST = "Show playlist";
        public const string TOOLTIP_SAVE_FINDER = "Bookmark this directory";
        public const string TOOLTIP_SAVE_PLAYLIST = "Save this playlist";
        public const string TOOLTIP_FINDER_ZOOMIN = "Zoom in";
        public const string TOOLTIP_FINDER_ZOOMOUT = "Zoom out";
        public const string TOOLTIP_FINDER_GO_UP = "Go up";
        public const string TOOLTIP_REFRESH_FINDER = "Reload";
        public const string TOOLTIP_SAVE_BUTTON = "Save this playlist";
        public const string TOOLTIP_DEL_BOOKMARK = "Delete the bookmark \"%s\"";
        public const string TOOLTIP_DEL_PLAYLIST = "Delete the playlist \"%s\"";
        public const string ERROR_WRITE_CONFIG = "Error: can not write to config file.\n";
        public const string ERROR_NO_MPLAYER = "mplayer command does not exist.\n";
        public const string ERROR_UNKOWN_OPTION = "%s: Unknown command line options \"%s\"";
        public const string ERROR_FAIL_TMP_DIR = "making a tmp directory was failed.\n";
        public const string ERROR_LOAD_ICON = "icon file can not load.\n";
        public const string ERROR_OPEN_PLAYLIST_FILE = "FileError at menu_bookmark_reset\n";
        public const string ERROR_CREATE_WINDOW = "ERROR: failed to create a window\n";
        public const string ERROR_OPEN_FILE = "FileError catched with file_info.path '%s' which is cannot open\n";
        public const string ERROR_FILE_DOES_NOT_EXISTS = "File does not exists (%s)\n";
        public const string ERROR_FILE_IS_NOT_A_DIRECTORY = "File is not a directory (%s)\n";
        public const string ERROR_FILE_IS_NOT_AN_AUDIO = "File is not an audio file (%s)\n";
        public const string ERROR_GST_MESSAGE = "Gstreamer messaging error\n";
        public const string ERROR_INVALID_OPTION_KEY = "Invalid key was found\n";
    }
}
