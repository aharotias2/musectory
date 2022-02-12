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

public class MusectoryApplication : Gtk.Application {
    private string config_dir;
    private Musectory.Options options;

    public static int main(string[] args) {
        Gst.init(ref args);
        MusectoryApplication app = new MusectoryApplication();
        app.setup_configs(ref args);
        return app.run();
    }

    public MusectoryApplication() {
        Object(application_id: Musectory.PROGRAM_NAME,
                flags: ApplicationFlags.FLAGS_NONE);
    }

    protected override void activate() {
        Musectory.Window window = new Musectory.Window(options);
        add_window(window);
        window.show_all();
    }

    private void setup_configs(ref unowned string[] args) {
        options = new Musectory.Options();
        try {
            options.parse_conf();
        } catch (Musectory.Error e) {
            stderr.printf(@"MusectoryError: $(e.message)\n");
        }
        try {
            options.parse_args(ref args);
        } catch (Musectory.Error e) {
            stderr.printf(@"MusectoryError: $(e.message)\n");
        }
        config_dir = options.get(Musectory.OptionKey.CONFIG_DIR);
        if (!FileUtils.test(config_dir, FileTest.IS_DIR)) {
            DirUtils.create_with_parents(options.get(Musectory.OptionKey.CONFIG_DIR), 0755);
        }
        if (!FileUtils.test(options.get(Musectory.OptionKey.CSS_PATH), FileTest.IS_REGULAR)) {
            try {
                FileUtils.set_contents(options.get(Musectory.OptionKey.CSS_PATH), Musectory.DEFAULT_CSS);
            } catch (GLib.FileError e) {
                stderr.printf(@"FileError: $(e.message)\n");
            }
        }
    }
}
