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

using Gdk;

namespace Moegi.TimeUtils {
    public double minutes_to_seconds(string time_str) {
        string[] parts = time_str.split(":", 3);
        int hours = parts.length == 3 ? int.parse(parts[0]) : 0;
        int minutes = parts.length == 3 ? int.parse(parts[1]) : int.parse(parts[0]);
        int seconds = parts.length == 3 ? int.parse(parts[2]) : int.parse(parts[1]);
        return hours * 360 + minutes * 60 + seconds;
    }

    public int compare(Time a, Time b) {
        if (a.year == b.year && a.month == b.month && a.day == b.day
                && a.hour == b.hour && a.minute == b.minute && a.second == b.second) {
            return 0;
        } else if (a.year < b.year || a.month < b.month || a.day < b.day
                || a.hour < b.hour || a.minute < b.minute || a.second < b.second) {
            return -1;
        } else {
            return 1;
        }
    }
}

