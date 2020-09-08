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

public class TestGstPlayer : TestBase{
    private static Posix.FILE output;

    public static int main(string[] args) {
        output = Posix.FILE.fdopen(1, "w");
        set_print_handler((text) => output.printf(text));
        Gst.init(ref args);
        GLib.MainLoop main_loop = new GLib.MainLoop();        
        try {
            string file_path = choose_file("/var/run/media/ta/TOSHIBAEXT/Music4");
            Tatam.GstPlayer player = new Tatam.GstPlayer();
            player.error_occured.connect((error) => {
                    stderr.printf(@"Error: $(error.message)\n");
                });
            player.finished.connect(() => {
                    main_loop.quit();
                });
            player.unpaused.connect(() => {
                    print("Unpaused\n");
                });
            player.paused.connect(() => {
                    print("Paused\n");
                });
            player.play(file_path);
            main_loop.run();
            return 0;
        } catch (GLib.Error e) {
            stderr.printf(@"Error: %s\n", e.message);
            return 1;
        }
    }
}
