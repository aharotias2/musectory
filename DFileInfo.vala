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
    }
}
