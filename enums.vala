namespace DPlayer {

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
        PLAYLIST,
        CONFIG,
        ABOUT,
        QUIT,
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