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
    public class StringJoiner {
        private Gee.List<string> parts_list;
        private string delimitter;
        private string prefix;
        private string postfix;

        public StringJoiner(string? delimitter = null, string? prefix = null, string? postfix = null) {
            this.delimitter = delimitter;
            this.prefix = prefix;
            this.postfix = postfix;
            this.parts_list = new Gee.ArrayList<string>();
        }

        public StringJoiner add(string parts) {
            parts_list.add(parts);
            return this;
        }

        public void add_all(Gee.List<string> string_list) {
            foreach (string parts in string_list) {
                parts_list.add(parts);
            }
        }

        public string to_string() {
            StringBuilder builder = new StringBuilder();
            if (prefix != null) {
                builder.append(prefix);
            }
            for (int i = 0; i < parts_list.size; i++) {
                builder.append(parts_list[i]);
                if (delimitter != null && i < parts_list.size - 1) {
                    builder.append(delimitter);
                }
            }
            if (postfix != null) {
                builder.append(postfix);
            }
            return builder.str;
        }
    }
}



