/*
 * This file is part of mpd.
 * 
 *     mpd is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 * 
 *     mpd is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 * 
 *     You should have received a copy of the GNU General Public License
 *     along with mpd.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright 2018 Takayuki Tanaka
 */

using Gdk;

namespace MyUtils {
    public class NumberUtils {
        public static int hex2int(string hex) {
            int result = 0;
            for (int i = 0; i < hex.length; i++) {
                if (hex.valid_char(i)) {
                    unichar c = hex.get_char(i);
                    if (c.isdigit()) {
                        result *= 16;
                        result += int.parse(c.to_string());
                    } else if (c.isalpha()) {
                        result *= 16;
                        if (c == 'a' || c == 'A') {
                            result += 10;
                        } else if (c == 'b' || c == 'B') {
                            result += 11;
                        } else if (c == 'c' || c == 'C') {
                            result += 12;
                        } else if (c == 'd' || c == 'D') {
                            result += 13;
                        } else if (c == 'e' || c == 'E') {
                            result += 14;
                        } else if (c == 'f' || c == 'F') {
                            result += 15;
                        }
                    }
                }
            }
            return result;
        }
    }

    public class TimeUtils {
        public static double minutes_to_seconds(string time_str) {
            string[] parts = time_str.split(":", 3);
            int hours = parts.length == 3 ? int.parse(parts[0]) : 0;
            int minutes = parts.length == 3 ? int.parse(parts[1]) : int.parse(parts[0]);
            int seconds = parts.length == 3 ? int.parse(parts[2]) : int.parse(parts[1]);

            return hours * 360 + minutes * 60 + seconds;
        }

        public static int compare(Time a, Time b) {
            if (a.year == b.year && a.month == b.month
                && a.day == b.day && a.hour == b.hour
                && a.minute == b.minute && a.second == b.second) {
                return 0;
            } else if (a.year < b.year || a.month < b.month
                       || a.day < b.day || a.hour < b.hour
                       || a.minute < b.minute || a.second < b.second) {
                return -1;
            } else {
                return 1;
            }
        }
    }

    class RGBAUtils {
        public static RGBA new_rgba_from_int(int red, int green, int blue, double alpha) {
            if ((0 <= red < 256) &&  (0 <= green < 256) && (0 <= blue < 256) && (0 <= alpha <= 1.0)) {
                RGBA rgba = { red / 256.0, green / 256.0, blue / 256.0, alpha };
                return rgba;
            } else {
                RGBA rgba = { 1.0, 1.0, 1.0, 1.0 };
                return rgba;
            }
        }

        public static RGBA new_rgba_from_string(string rgb_string, double alpha) {
            string r_s = rgb_string.substring(0, 2);
            string g_s = rgb_string.substring(2, 2);
            string b_s = rgb_string.substring(4, 2);
            return new_rgba_from_int(NumberUtils.hex2int(r_s),
                                     NumberUtils.hex2int(g_s),
                                     NumberUtils.hex2int(b_s),
                                     alpha);
        }
    }

    class PixbufUtils {
        public static Gdk.Pixbuf scale_limited(Gdk.Pixbuf pixbuf, int size) {
            size = int.max(10, size);
            if (pixbuf.width >= pixbuf.height) {
                if (size >= pixbuf.width) {
                    return pixbuf.copy();
                } else {
                    return pixbuf.scale_simple(size,
                                               (int) (size * ((double) pixbuf.height / pixbuf.width)),
                                               Gdk.InterpType.BILINEAR);
                }
            } else {
                if (size >= pixbuf.height) {
                    return pixbuf.copy();
                } else {
                    return pixbuf.scale_simple((int) (size * ((double) pixbuf.width / pixbuf.height)),
                                               size,
                                               Gdk.InterpType.BILINEAR);
                }
            }
        }

    }

    public class StringUtils {
        public static List<string> array2list(string[] array) {
            List<string> list = new List<string>();
            foreach (string item in array) {
                list.append(item);
            }
            return list;
        }
    }

    public class FilePathUtils {
        public static string extension_of(string file_path) {
            return file_path.slice(file_path.last_index_of(".") + 1, file_path.length);
        }

        public static string remove_extension(string file_path) {
            return file_path.slice(0, file_path.last_index_of("."));
        }
    }

    public class FileUtils {
        public static int compare_mtime(string file1_path, string file2_path) {
            return MyUtils.TimeUtils.compare(get_file_mtime(file1_path), get_file_mtime(file2_path));
        }

        public static Time get_file_mtime(string file_path) {
            Posix.Stat file_status;
            Posix.stat(file_path, out file_status);
            return Time.local(file_status.st_mtime);
        }

        public static bool is_empty(string file_path) {
            Posix.Stat file_status;
            Posix.stat(file_path, out file_status);
            return ((uint) file_status.st_size) == 0;
        }

        public static void create_empty_file(string file_path) throws Error, IOError {
            if (!GLib.FileUtils.test(file_path, FileTest.EXISTS)) {
                File f = File.new_for_path(file_path);
                var stream = f.create(FileCreateFlags.NONE);
                stream.close();
            }
        }
    }
}

