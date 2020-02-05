namespace Mpd {
    public const string PROGRAM_NAME = "mpd";
    
    namespace StyleClass {
        public const string TITLEBUTTON = "titlebutton";
        public const string FLAT = "flat";
        public const string LINKED = "linked";
        public const string SIDEBAR = "sidebar";
        public const string TIME_LABEL_CURRENT = "time_label_current";
        public const string TIME_LABEL_REST = "time_label_rest";
        public const string ARTWORK_BACKGROUND = "artwork_background";
        public const string VIEW = "view";
        public const string FINDER_ICON = "finder_icon";
        public const string FINDER_MINI_ICON = "finder_mini_icon";
        public const string FINDER_ITEM_LABEL = "finder_item_label";
        public const string FINDER_BUTTON = "finder_button";
        public const string WHILE_LABEL = "while_label";
    }

    namespace IconName {
        namespace Symbolic {
            public const string FOLDER = "folder-symbolic";
            public const string FOLDER_OPEN = "folder-open-symbolic";
            public const string AUDIO_FILE = "audio-x-generic-symbolic";
            public const string VIEW_LIST = "view-list-symbolic";
            public const string VIEW_GRID = "view-grid-symbolic";
            public const string VIEW_MORE = "view-more-symbolic";
            public const string BOOKMARK_NEW = "bookmark-new-symbolic";
            public const string HELP_FAQ = "help-faq-symbolic";
            public const string EXIT = "application-exit-symbolic";
            public const string OPEN_MENU = "open-menu-symbolic";
            public const string GO_UP = "go-up-symbolic";
            public const string GO_DOWN = "go-down-symbolic";
            public const string GO_PREVIOUS = "go-previous-symbolic";
            public const string MEDIA_PLAYBACK_START = "media-playback-start-symbolic";
            public const string MEDIA_PLAYBACK_PAUSE = "media-playback-pause-symbolic";
            public const string MEDIA_SKIP_FORWARD = "media-skip-forward-symbolic";
            public const string MEDIA_SKIP_BACKWARD = "media-skip-backward-symbolic";
            public const string AUDIO_VOLUME_MEDIUM = "audio-volume-medium-symbolic";
            public const string AUDIO_VOLUME_MUTED = "audio-volume-muted-symbolic";
            public const string AUDIO_VOLUME_LOW = "audio-volume-low-symbolic";
            public const string AUDIO_VOLUME_HIGH = "audio-volume-high-symbolic";
            public const string MEDIA_PLAYLIST_SHUFFLE = "media-playlist-shuffle-symbolic";
            public const string MEDIA_PLAYLIST_REPEAT = "media-playlist-repeat-symbolic";
            public const string USER_BOOKMARKS = "user-bookmarks-symbolic";
            public const string MEDIA_OPTICAL = "media-optical-symbolic";
            public const string PREFERENCES_SYSTEM = "preferences-system-symbolic";
            public const string LIST_REMOVE = "list-remove-symbolic";
            public const string LIST_ADD = "list-add-symbolic";
            public const string WINDOW_CLOSE = "window-close-symbolic";
            public const string DOCUMENT_SAVE = "document-save-symbolic";
            public const string ZOOM_IN = "zoom-in-symbolic";
            public const string ZOOM_OUT = "zoom-out-symbolic";
            public const string APPLICATIONS_SYSTEM = "applications-system-symbolic";
            public const string HELP_ABOUT = "help-about-symbolic";
            public const string VIEW_REFRESH = "view-refresh-symbolic";
        }
        public const string AUDIO_FILE = "audio-x-generic";
        public const string MEDIA_OPTICAL = "media-optical";
        public const string FOLDER_MUSIC = "folder-music";
        public const string FOLDER = "folder";
        public const string GO_UP = "go-up";
        public const string GO_NEXT = "go-next";
        public const string GO_PREVIOUS = "go-previous";
        public const string DOCUMENT_SAVE = "document-save";
    }
    
    namespace Text {
        public const string EMPTY = "";
        public const string PROGRAM_NAME = "mpd";
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
        public const string CONFIG_DIALOG_HEADER_CSD = "Use CSD?";
        public const string CONFIG_DIALOG_PLAY_STYLE = "Play all files when one file was selected?";
        public const string DIALOG_YES = "Yes";
        public const string DIALOG_NO = "No";
        public const string DIALOG_OPEN_FILE = "Open File";
        public const string PLAYLIST_SAVE_NAME = "Enter new playlist name:";
        public const string CONFIRM_OVERWRITE = "A playlist %s exists. Do you overwrite it?";
        public const string CONFIRM_REMOVE_BOOKMARK = "Do you really remove this bookmark?";
        public const string CONFIRM_REMOVE_PLAYLIST = "Do you really remove this playlist?";
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
        public const string DEFAULT_CSS = """
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

/***********************************************************
 *                  dplayer style sheet                    *
 ***********************************************************/
.playlist_title {
    padding: 6px 0px 2px 0px;
    font-size: 12px;
}

.playlist_album {
    padding: 2px 0px 6px 0px;
    font-size: 11px;
}

.playlist_artist {
    padding: 6px 0px 2px 0px;
    font-size: 9px;
    font-style: italic;
}

.playlist_genre {
    padding: 2px 0px 6px 0px;
    font-size: 9px;
    font-style: italic;
}

.artwork_background {
    background-color: rgba(0, 0, 0, 0.85);
    color: #ffffff;
}

.tooltip {
    color: rgba(252, 252, 252, 1.0);
    font-style: italic;
    padding: 4px;
    /* not working */
    border-radius: 2px;
    box-shadow: none;
}

.tooltip.background {
    box-shadow: inset 0px 1px rgba(0, 0, 0, 0.5);
    background-color: rgba(9, 9, 9, 0.5);
}
.finder_icon {
    box-shadow: 10px 10px 10px 10px rgba(0, 0, 0, 0.4);
}
.finder_item_label {
    background-color: rgba(10, 10, 10, 0.5);
    color: rgba(228, 228, 228, 1.0);
}
.finder_mini_icon {
    background-color: rgba(128, 128, 128, 0.0);
}
.finder_button {
}
.while_label {
    background-color: rgba(16, 16, 16, 0.5);
    color: rgba(228, 228, 228, 1.0);
}
""";
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
        public const string ERROR_WRITE_CONFIG = "Error: can not write to config file.\n";
        public const string ERROR_NO_MPLAYER = "mplayer command does not exist.\n";
        public const string ERROR_UNKOWN_OPTION = "%s: Unknown command line options \"%s\"";
        public const string ERROR_FAIL_TMP_DIR = "making a tmp directory was failed.\n";
        public const string ERROR_LOAD_ICON = "icon file can not load.\n";
        public const string ERROR_OPEN_PLAYLIST_FILE = "FileError at menu_bookmark_reset\n";
        public const string ERROR_CREATE_WINDOW = "ERROR: failed to create a window\n";
        public const string ERROR_OPEN_FILE = "FileError catched with file_info.path '%s' which is cannot open\n";
    }
}
