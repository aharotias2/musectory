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
 * Copyright 2020 Takayuki Tanaka
 */

public class TestMetadata : TestBase {
    private static Posix.FILE output;

    public static int main(string[] args) {
        Gst.init(ref args);
        TestMetadata tester = new TestMetadata();
        return tester.start();
    }

    public int start() {
        output = Posix.FILE.fdopen(1, "w");
        set_print_handler((text) => output.printf(text));
        GLib.MainLoop main_loop = new GLib.MainLoop();
        try {
            string file_path = choose_file("/var/run/media/ta/TOSHIBAEXT/Music4");
            int status = 0;
            run_test.begin(file_path, (res, obj) => {
                    status = run_test.end(obj);
                    main_loop.quit();
                });
            main_loop.run();
            return status;
        } catch (GLib.Error e) {
            stderr.printf(@"Error: %s\n", e.message);
            return 1;
        }
    }

    private async int run_test(string file_path) {
        int status = 0;
        new Thread<int>(null, () => {
                try {
                    Tatam.FileInfoAdapter file_info_adapter = new Tatam.FileInfoAdapter();
                    Tatam.FileInfo file_info = file_info_adapter.read_metadata_from_path(file_path);
                    print_file_info_pretty(file_info);
                } catch (Tatam.Error e) {
                    stderr.printf(@"Tatam.Error: %s\n", e.message);
                    status = 2;
                } catch (GLib.Error e) {
                    stderr.printf(@"GLib.Error: %s\n", e.message);
                    status = 2;
                }
                Idle.add(run_test.callback);
                return 0;
            });
        yield;
        return status;
    }
}
