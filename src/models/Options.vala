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
 * Copyright 2018 Takayuki Tanaka
 */

namespace Tatam {
    public class Options {
        private Gee.Map<Tatam.OptionKey, Gee.List<string>> config_map;
        
        public Options() {
            config_map = new Gee.HashMap<Tatam.OptionKey, Gee.List<string>>();
            {
                foreach (OptionKey key in OptionKey.values()) {
                    config_map.set(key, new Gee.ArrayList<string>());
                }
                string home_dir = Environment.get_home_dir();
                string config_dir = @"$(home_dir)/.$(PROGRAM_NAME)";
                string css_path = @"$(config_dir)/$(PROGRAM_NAME).css";
                config_map.get(OptionKey.CONFIG_DIR).add(config_dir);
                config_map.get(OptionKey.CSS_PATH).add(css_path);
                config_map.get(OptionKey.LAST_VISITED_DIR).add(@"$(home_dir)/Music");
                config_map.get(OptionKey.FINDER_ICON_SIZE).add(128.to_string());
                config_map.get(OptionKey.PLAYLIST_THUMBNAIL_SIZE).add(48.to_string());
                config_map.get(OptionKey.CONTROLLER_IMAGE_SIZE_MIN).add(64.to_string());
                config_map.get(OptionKey.CONTROLLER_IMAGE_SIZE_MAX).add(127.to_string());
            }
        }

        public string? get(OptionKey key) {
            if (config_map.get(key).size > 0) {
                return config_map.get(key).last();
            } else {
                return null;
            }
        }

        public void set(OptionKey key, string value) {
            config_map.get(key).add(value);
        }

        public Gee.Set<OptionKey> keys() {
            return config_map.keys;
        }
        
        public void parse_args(ref unowned string[] args) throws Tatam.Error {
            for (int i = 1; i < args.length; i++) {
                OptionKey key;
                try {
                    key = OptionKey.value_of(args[i]);
                } catch (Tatam.Error e) {
                    stderr.printf(@"TatamError: $(e.message) that is $(args[i])\n");
                    continue;
                }
                switch (key) {
                case Tatam.OptionKey.CSS_PATH:
                case Tatam.OptionKey.CONFIG_DIR:
                    File option_file = File.new_for_path(args[i + 1]);
                    if (option_file.query_exists()) {
                        config_map.get(key).add(option_file.get_path());
                        i++;
                    } else {
                        throw new Tatam.Error.FILE_DOES_NOT_EXISTS(Tatam.Text.ERROR_FILE_DOES_NOT_EXISTS);
                    }
                    break;
                default:
                    string value = args[i + 1];
                    config_map.get(key).add(value);
                    i++;
                    break;
                }
            }
        }

        public void parse_conf() throws Tatam.Error {
            try {
                string? config_dir = config_map.get(OptionKey.CONFIG_DIR).last();
                string config_file_path = config_dir + "/" + Tatam.PROGRAM_NAME + ".conf";
                File config_file = File.new_for_path(config_file_path);
                DataInputStream dis = new DataInputStream(config_file.read());
                string? line = null;
                while ((line = dis.read_line()) != null) {
                    int pos_eq = line.index_of_char('=');
                    string key = line.substring(0, pos_eq);
                    string option_value = line.substring(pos_eq + 1);
                    debug(@"config key = $(key), value = $(option_value)");
                    Tatam.OptionKey option_key;
                    try {
                        option_key = OptionKey.value_of(key);
                    } catch (Tatam.Error e) {
                        stderr.printf(@"TatamError: $(e.message)\n");
                        continue;
                    }
                    switch (option_key) {
                    case Tatam.OptionKey.CSS_PATH:
                    case Tatam.OptionKey.CONFIG_DIR:
                        File option_file = File.new_for_path(option_value);
                        if (option_file.query_exists()) {
                            config_map.get(option_key).add(option_file.get_path());
                        } else {
                            throw new Tatam.Error.FILE_DOES_NOT_EXISTS(Tatam.Text.ERROR_FILE_DOES_NOT_EXISTS);
                        }
                        break;
                    default:
                        config_map.get(option_key).add(option_value);
                        break;
                    }
                }
            } catch (Tatam.Error e) {
                stderr.printf(@"TatamError: $(e.message)\n");
                throw e;
            } catch (GLib.IOError e) {
                stderr.printf(@"IOError: $(e.message)\n");
            } catch (GLib.Error e) {
                stderr.printf(@"GLibError: $(e.message)\n");
            }
        }
    }
}
