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

public class TatamApplication : Gtk.Application {
    private static string config_dir;

    public Tatam.Options options { get; set; }

    public static int main(string[] args) {
        Gst.init(ref args);
        TatamApplication app = new TatamApplication() {
            options = setup_configs(ref args)
        };
        app.run();
        Gtk.main();
        return 0;
    }

    public TatamApplication() {
        Object(application_id: "com.github.aharotias2.tatam",
                flags: ApplicationFlags.FLAGS_NONE);
    }
    
    protected override void activate() {
        TatamWindow window = new TatamWindow(this, options);
        window.destroy.connect(() => quit());
        window.show_all();
    }
    
    private static Tatam.Options setup_configs(ref unowned string[] args) {
        Tatam.Options options = new Tatam.Options();
        try {
            options.parse_conf();
        } catch (Tatam.Error e) {
            stderr.printf(@"TatamError: $(e.message)\n");
        }
        try {
            options.parse_args(ref args);
        } catch (Tatam.Error e) {
            stderr.printf(@"TatamError: $(e.message)\n");
        }
        config_dir = options.get(Tatam.OptionKey.CONFIG_DIR);
        if (!FileUtils.test(config_dir, FileTest.IS_DIR)) {
            DirUtils.create_with_parents(options.get(Tatam.OptionKey.CONFIG_DIR), 0755);
        }
        if (!FileUtils.test(options.get(Tatam.OptionKey.CSS_PATH), FileTest.IS_REGULAR)) {
            try {
                FileUtils.set_contents(options.get(Tatam.OptionKey.CSS_PATH), Tatam.DEFAULT_CSS);
            } catch (GLib.FileError e) {
                stderr.printf(@"FileError: $(e.message)\n");
            }
        }
        return options;
    }
}
