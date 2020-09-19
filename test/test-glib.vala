int main() {
    File file = File.new_for_path("/home/ta/Work/tatam/src/tatam.vala");
    FileInfo file_info = file.query_info("standard::*", 0);
    print(@"File info name: $(file_info.get_name())\n");

    return 0;
}
