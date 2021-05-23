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
 * Copyright 2018 Takayuki Tanaka
 */

namespace Moegi.RGBAUtils {
    public Gdk.RGBA new_rgba_from_int(int red, int green, int blue, double alpha) {
        if ((0 <= red < 256) &&  (0 <= green < 256) && (0 <= blue < 256) && (0 <= alpha <= 1.0)) {
            Gdk.RGBA rgba = { red / 256.0, green / 256.0, blue / 256.0, alpha };
            return rgba;
        } else {
            Gdk.RGBA rgba = { 1.0, 1.0, 1.0, 1.0 };
            return rgba;
        }
    }

    public Gdk.RGBA new_rgba_from_string(string rgb_string, double alpha) {
        string hex_red_part = rgb_string.substring(0, 2);
        string hex_green_part = rgb_string.substring(2, 2);
        string hex_blue_part = rgb_string.substring(4, 2);
        return new_rgba_from_int(
                Hex.value_of(hex_red_part).to_int(),
                Hex.value_of(hex_green_part).to_int(),
                Hex.value_of(hex_blue_part).to_int(),
                alpha);
    }
}

