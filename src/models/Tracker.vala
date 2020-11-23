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
    public interface TrackerInterface {
        public abstract uint current { get; set; }
        public abstract uint length { get; }
        public abstract uint max { get; }
        public abstract uint min { get; }
        public abstract bool repeating { get; set; }
        public abstract bool shuffling { get; set; }
        public abstract void reset(uint length, uint index);
        public abstract bool has_next();
        public abstract bool has_previous();
        public abstract uint next();
        public abstract uint previous();
    }

    public class Tracker : TrackerInterface {
        bool repeating_value;
        bool shuffling_value;
        uint[] seq;
        uint current_index;

        public uint current {
            get {
                if (seq == null) {
                    return 0;
                } else {
                    return seq[current_index];
                }
            }
            set {
                for (int i = 0; i < seq.length; i++) {
                    if (seq[i] == value) {
                        current_index = i;
                        break;
                    }
                }
                if (shuffling_value) {
                    create_shuffle_seq();
                }
            }
        }

        public uint length {
            get {
                if (seq == null) {
                    return 0;
                } else {
                    return seq.length;
                }
            }
        }

        public uint max {
            get {
                if (seq == null) {
                    return 0;
                } else {
                    return seq.length - 1;
                }
            }
        }

        public uint min {
            get {
                return 0;
            }
        }

        public bool repeating {
            set {
                repeating_value = value;
            }
            get {
                return repeating_value;
            }
        }

        public bool shuffling {
            set {
                shuffling_value = value;
                if (seq != null) {
                    if (shuffling_value) {
                        create_shuffle_seq();
                    } else {
                        uint tmp = seq[current_index];
                        for (int i = 0; i < seq.length; i++) {
                            seq[i] = i;
                            if (i == tmp) {
                                current_index = i;
                            }
                        }
                    }
                }
            }
            get {
                return shuffling_value;
            }
        }

        public Tracker() {
            seq = null;
            shuffling_value = false;
            repeating_value = false;
            current_index = 0;
        }

        public void reset(uint length, uint index) {
            debug("Tracker resest length = %u, index = %u", length, index);
            if (length == 0) {
                seq = null;
            } else {
                seq = new uint[length];
                for (int i = 0; i < seq.length; i++) {
                    seq[i] = i;
                }
                if (index < seq.length) {
                    current_index = index;
                } else {
                    Random.set_seed(new DateTime.now_local().get_microsecond());
                    current_index = Random.int_range(0, seq.length);
                    create_shuffle_seq();
                }
            }
        }

        public bool has_next() {
            if (repeating_value) {
                return true;
            } else if (current_index == seq.length - 1) {
                return false;
            } else {
                return true;
            }
        }

        public bool has_previous() {
            if (shuffling_value) {
                return true;
            } else if (current_index == 0) {
                return false;
            } else {
                return true;
            }
        }

        public uint next() {
            if (current_index == seq.length - 1) {
                if (repeating_value) {
                    if (shuffling_value) {
                        create_shuffle_seq();
                        next();
                        create_shuffle_seq();
                    } else {
                        current_index = 0;
                    }
                } else {
                    return seq[current_index];
                }
            } else {
                current_index++;
            }
            return seq[current_index];
        }

        public uint previous() {
            if (current_index == 0) {
                if (shuffling_value) {
                    create_shuffle_seq();
                    return seq[current_index];
                }
                return seq[0];
            }
            current_index--;
            return seq[current_index];
        }

        private void create_shuffle_seq() {
            int[] dummy = new int[seq.length];
            uint tmp = seq[current_index];
            for (int i = 0; i < seq.length; i++) {
                dummy[i] = i + 1;
                seq[i] = 0;
            }

            Random.set_seed(new DateTime.now_local().get_microsecond());
            current_index = 0;
            seq[0] = tmp;
            for (int i = 0; i < seq.length; i++) {
                if (dummy[i] == tmp + 1) {
                    dummy[i] = 0;
                    break;
                }
            }
            uint rnd;
            for (int i = 1; i < seq.length; i++) {
                rnd = Random.int_range(1, seq.length);
                while (dummy[rnd] == 0) {
                    rnd = Random.int_range(0, seq.length);
                }
                seq[i] = dummy[rnd] - 1;
                dummy[rnd] = 0;
            }
        }
    }
}

