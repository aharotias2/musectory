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

using Gdk;

namespace Tatam.NumberUtils {
    public int hex2int(string hex) {
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

