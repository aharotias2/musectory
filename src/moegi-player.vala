/*
 * This file is part of moegi-player.
 *
 *     moegi-player is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     moegi-player is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with moegi-player.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright 2020 Takayuki Tanaka
 */

public class MoegiApplication : Gtk.Application {
    private string config_dir;
    private Moegi.Options options;

    public static int main(string[] args) {
        Gst.init(ref args);
        MoegiApplication app = new MoegiApplication();
        app.setup_configs(ref args);
        return app.run();
    }

    public MoegiApplication() {
        Object(application_id: Moegi.PROGRAM_NAME,
                flags: ApplicationFlags.FLAGS_NONE);
    }

    protected override void activate() {
        Moegi.Window window = new Moegi.Window(options);
        add_window(window);
        window.show_all();
    }

    private void setup_configs(ref unowned string[] args) {
        options = new Moegi.Options();
        try {
            options.parse_conf();
        } catch (Moegi.Error e) {
            stderr.printf(@"MoegiError: $(e.message)\n");
        }
        try {
            options.parse_args(ref args);
        } catch (Moegi.Error e) {
            stderr.printf(@"MoegiError: $(e.message)\n");
        }
        config_dir = options.get(Moegi.OptionKey.CONFIG_DIR);
        if (!FileUtils.test(config_dir, FileTest.IS_DIR)) {
            DirUtils.create_with_parents(options.get(Moegi.OptionKey.CONFIG_DIR), 0755);
        }
        if (!FileUtils.test(options.get(Moegi.OptionKey.CSS_PATH), FileTest.IS_REGULAR)) {
            try {
                FileUtils.set_contents(options.get(Moegi.OptionKey.CSS_PATH), Moegi.DEFAULT_CSS);
            } catch (GLib.FileError e) {
                stderr.printf(@"FileError: $(e.message)\n");
            }
        }
    }
}
