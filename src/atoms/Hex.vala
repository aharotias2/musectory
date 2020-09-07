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

namespace Tatam {
    public class Hex {
        private const string hex_pattern = "[a-fA-F0-9]+";
        private static Regex? hex_regex;
        public string data { get; private set; }

        private Hex(string hex_string) {
            this.data = hex_string;
        }
        
        public static Hex? value_of(string hex_string) {
            if (hex_regex == null) {
                try {
                    hex_regex = new Regex(hex_pattern);
                } catch (RegexError e) {
                    stderr.printf(@"FATAL RegexError: $(e.message)\n");
                    Process.exit(1);
                }
            }

            if (hex_regex.match(hex_string)) {
                Hex hex = new Hex(hex_string);
                return hex;
            } else {
                return null;
            }
        }

        public int to_int() {
            int result = 0;
            for (int i = 0; i < data.length; i++) {
                if (data.valid_char(i)) {
                    unichar c = data.get_char(i);
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
}
