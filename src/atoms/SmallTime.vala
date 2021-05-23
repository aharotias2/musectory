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

namespace Moegi {
    public class SmallTime : GLib.Object {
        public const string TIME_PATTERN = "^([0-9]*:)?([0-5]?[0-9]:)?[0-5]?[0-9](\\.[0-5])?$";
        public const int HOUR_IN_MILLISECONDS = 3600000;
        public const int MINUTE_IN_MILLISECONDS = 60000;
        public const int SECOND_IN_MILLISECONDS = 1000;
        public const int DECISECOND_IN_MILLISECONDS = 100;

        public static Regex? time_regex;

        public enum FormatType {
            HOURS_MINUTES_SECONDS_DECISECONDS,
            MINUTES_SECONDS_DECISECONDS,
            SECONDS_DECISECONDS,
            MINUMUM,
        }

        private int hours_value;
        private int minutes_value;
        private int seconds_value;
        private int deciseconds_value;
        private int milliseconds_value;
        private bool with_deciseconds_value;
        private FormatType format_type_value;

        private delegate string SmallTimeToStringFunc();
        private SmallTimeToStringFunc to_string_func;
        private SmallTimeToStringFunc to_string_without_deciseconds_func;

        public int milliseconds {
            get {
                return milliseconds_value;
            }
            set {
                milliseconds_value = value;
                hours_value = milliseconds_value / HOUR_IN_MILLISECONDS;
                minutes_value = milliseconds_value % HOUR_IN_MILLISECONDS / MINUTE_IN_MILLISECONDS;
                seconds_value = milliseconds_value % MINUTE_IN_MILLISECONDS / SECOND_IN_MILLISECONDS;
                deciseconds_value = milliseconds_value % SECOND_IN_MILLISECONDS / DECISECOND_IN_MILLISECONDS;
            }
        }

        public double seconds {
            get {
                return milliseconds_value / SECOND_IN_MILLISECONDS;
            }
        }

        public FormatType format_type {
            get {
                return format_type_value;
            }
            set {
                format_type_value = value;
                set_to_string_func(format_type_value);
            }
        }

        private void init_time_regex() {
            if (time_regex == null) {
                try {
                    time_regex = new Regex(TIME_PATTERN);
                } catch (RegexError e) {
                    stderr.printf(@"RegexError: $(e.message)\n");
                    Process.exit(1);
                }
            }
        }

        public SmallTime(FormatType format_type = FormatType.MINUMUM) {
            this.with_deciseconds_value = true;
            this.format_type = format_type;
            init_time_regex();
            this.milliseconds_value = 0;
            set_to_string_func(format_type);
        }

        public SmallTime.from_seconds(int seconds, FormatType format_type = FormatType.MINUMUM) {
            this.with_deciseconds_value = true;
            this.format_type = format_type;
            init_time_regex();
            this.milliseconds = seconds * SECOND_IN_MILLISECONDS;
            set_to_string_func(format_type);
        }

        public SmallTime.from_milliseconds(int milliseconds, FormatType format_type = FormatType.MINUMUM) {
            this.with_deciseconds_value = true;
            this.format_type = format_type;
            init_time_regex();
            this.milliseconds = milliseconds;
            set_to_string_func(format_type);
        }

        public SmallTime.from_string(string time_string, FormatType format_type = FormatType.MINUMUM) {
            this.with_deciseconds_value = true;
            this.format_type = format_type;
            init_time_regex();
            if (!time_regex.match(time_string)) {
                stderr.printf(@"Time pattern is not matched ($(time_string))\n");
                milliseconds = 0;
                set_to_string_func(format_type);
                return;
            }
            string[] parts1 = time_string.split(":");
            string[] parts2;
            int small_time = 0;
            switch (parts1.length) {
              case 3:
                parts2 = parts1[2].split(".");
                small_time += int.parse(parts1[0]) * HOUR_IN_MILLISECONDS;
                small_time += int.parse(parts1[1]) * MINUTE_IN_MILLISECONDS;
                small_time += int.parse(parts2[0]) * SECOND_IN_MILLISECONDS;
                if (parts2.length >= 2) {
                    small_time += int.parse(parts2[1].substring(0, 1)) * DECISECOND_IN_MILLISECONDS;
                }
                break;
              case 2:
                parts2 = parts1[1].split(".");
                small_time += int.parse(parts1[0]) * MINUTE_IN_MILLISECONDS;
                small_time += int.parse(parts2[0]) * SECOND_IN_MILLISECONDS;
                if (parts2.length >= 2) {
                    small_time += int.parse(parts2[1].substring(0, 1)) * DECISECOND_IN_MILLISECONDS;
                }
                break;
              case 1:
                parts2 = parts1[0].split(".");
                small_time += int.parse(parts2[0]) * SECOND_IN_MILLISECONDS;
                if (parts2.length >= 2) {
                    small_time += int.parse(parts2[1].substring(0, 1)) * DECISECOND_IN_MILLISECONDS;
                }
                break;
              case 0:
                small_time = 0;
                break;
            }
            milliseconds = small_time;
            set_to_string_func(format_type);
        }

        public SmallTime minus(SmallTime subject) {
            return new SmallTime.from_milliseconds(this.milliseconds - subject.milliseconds, format_type);
        }

        public string to_string() {
            return to_string_func();
        }

        public string to_string_without_deciseconds() {
            return to_string_without_deciseconds_func();
        }

        private void set_to_string_func(FormatType format_type = MINUMUM) {
            switch (format_type) {
              case FormatType.HOURS_MINUTES_SECONDS_DECISECONDS:
                to_string_func = to_string_with_hours;
                to_string_without_deciseconds_func = to_string_with_hours_without_deciseconds;
                break;
              case FormatType.MINUTES_SECONDS_DECISECONDS:
                to_string_func = to_string_without_hours;
                to_string_without_deciseconds_func = to_string_without_hours_and_deciseconds;
                break;
              case FormatType.SECONDS_DECISECONDS:
                to_string_func = to_string_without_minutes;
                to_string_without_deciseconds_func = to_string_without_minutes_and_deciseconds;
                break;
              case FormatType.MINUMUM:
            default:
                if (milliseconds_value > HOUR_IN_MILLISECONDS) {
                    this.format_type = FormatType.HOURS_MINUTES_SECONDS_DECISECONDS;
                } else if (milliseconds_value > MINUTE_IN_MILLISECONDS) {
                    this.format_type = FormatType.MINUTES_SECONDS_DECISECONDS;
                } else if (milliseconds_value > SECOND_IN_MILLISECONDS) {
                    this.format_type = FormatType.SECONDS_DECISECONDS;
                } else {
                    this.format_type = FormatType.SECONDS_DECISECONDS;
                }
                set_to_string_func(this.format_type);
                break;
            }
        }

        private string to_string_with_hours() {
            return "%u:%02u:%02u.%u".printf(hours_value, minutes_value, seconds_value, deciseconds_value);
        }

        private string to_string_with_hours_without_deciseconds() {
            return "%u:%02u:%02u".printf(hours_value, minutes_value, seconds_value);
        }

        private string to_string_without_hours() {
            return "%2u:%02u.%u".printf(minutes_value, seconds_value, deciseconds_value);
        }

        private string to_string_without_hours_and_deciseconds() {
            return "%2u:%02u".printf(minutes_value, seconds_value);
        }

        private string to_string_without_minutes() {
            return "%2u.%u".printf(seconds_value, deciseconds_value);
        }

        private string to_string_without_minutes_and_deciseconds() {
            return "%2u".printf(seconds_value);
        }

        private string to_string_seconds() {
            return "0.%u".printf(deciseconds_value);
        }

        private string to_string_seconds_without_deciseconds() {
            return "0";
        }
    }
}
