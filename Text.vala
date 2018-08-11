namespace DPlayer {
    namespace StyleClass {
        public const string TITLEBUTTON = "titlebutton";
        public const string FLAT = "flat";
        public const string LINKED = "linked";
        public const string SIDEBAR = "sidebar";
        public const string TIME_LABEL_CURRENT = "time_label_current";
        public const string TIME_LABEL_REST = "time_label_rest";
        public const string ARTWORK_BACKGROUND = "artwork_background";
        public const string VIEW = "view";
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
            public const string WINDOW_CLOSE = "window-close-symbolic";
            public const string DOCUMENT_SAVE = "document-save-symbolic";
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
        public const string PROGRAM_NAME = "dplayer";
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
        public const string DEFAULT_CSS = "/*\n"+
            " * This file is part of dplayer.\n"+
            " * \n"+
            " *     dplayer is free software: you can redistribute it and/or modify\n"+
            " *     it under the terms of the GNU General Public License as published by\n"+
            " *     the Free Software Foundation, either version 3 of the License, or\n"+
            " *     (at your option) any later version.\n"+
            " * \n"+
            " *     dplayer is distributed in the hope that it will be useful,\n"+
            " *     but WITHOUT ANY WARRANTY; without even the implied warranty of\n"+
            " *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n"+
            " *     GNU General Public License for more details.\n"+
            " * \n"+
            " *     You should have received a copy of the GNU General Public License\n"+
            " *     along with dplayer.  If not, see <http://www.gnu.org/licenses/>.\n"+
            " * \n"+
            " * Copyright 2018 Takayuki Tanaka\n"+
            " */\n"+
            "\n"+
            "/***********************************************************\n"+
            " *                  dplayer style sheet                    *\n"+
            " ***********************************************************/\n"+
            ".title {\n"+
            "    font-size: 17px;\n"+
            "}\n"+
            "\n"+
            ".album {\n"+
            "    font-size: 12px;\n"+
            "}\n"+
            "\n"+
            ".artist, .genre {\n"+
            "    font-size: 12px;\n"+
            "    font-style: italic;\n"+
            "}\n"+
            "\n"+
            ".artwork_background {\n"+
            "    background-color: rgba(0, 0, 0, 0.85);\n"+
            "    color: #ffffff;\n"+
            "}\n"+
            "\n"+
            ".tooltip {\n"+
            "    color: rgba(252, 252, 252, 1.0);\n"+
            "    font-style: italic;\n"+
            "    padding: 4px;\n"+
            "    /* not working */\n"+
            "    border-radius: 2px;\n"+
            "    box-shadow: none;\n"+
            "}\n"+
            "\n"+
            ".tooltip.background {\n"+
            "    box-shadow: inset 0px 1px rgba(0, 0, 0, 0.5);\n"+
            "    background-color: rgba(9, 9, 9, 0.5);\n"+
            "}\n"+
            "\n";
        public const string MARKUP_BOLD_ITALIC = "<b><i>%s</i></b>";
        public const string FINDER_LOAD_FILES = "Loading data from disk...";
        public const string FILE_LOADED = "%s is loaded";
        public const string TOOLTIP_SHOW_FINDER = "Show finder";
        public const string TOOLTIP_SHOW_PLAYLIST = "Show playlist";
        public const string TOOLTIP_SAVE_FINDER = "Bookmark this directory";
        public const string TOOLTIP_SAVE_PLAYLIST = "Save this playlist";
        public const string ERROR_WRITE_CONFIG = "Error: can not write to config file.\n";
        public const string ERROR_NO_MPLAYER = "mplayer command does not exist.\n";
        public const string ERROR_UNKOWN_OPTION = "%s: Unknown command line options \"%s\"";
        public const string ERROR_FAIL_TMP_DIR = "making a tmp directory was failed.\n";
        public const string ERROR_LOAD_ICON = "icon file can not load.\n";
        public const string ERROR_OPEN_PLAYLIST_FILE = "FileError at menu_bookmark_reset\n";
        public const string ERROR_CREATE_WINDOW = "ERROR: failed to create a window";
        public const string ERROR_OPEN_FILE = "FileError catched with file_info.path '%s' which is cannot open";
    }
}
