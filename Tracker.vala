class Tracker {
    bool repeat;
    bool shuffle;
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
            if (shuffle) {
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

    public Tracker() {
        seq = null;
        shuffle = false;
        repeat = false;
        current_index = 0;
    }

    public void reset(uint length, uint index) {
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

    public void toggle_repeat() {
        repeat = !repeat;
    }

    public void toggle_shuffle() {
        shuffle = ! shuffle;
        if (seq != null) {
            if (shuffle) {
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

    public bool has_next() {
        if (repeat) {
            return true;
        } else if (current_index == seq.length - 1) {
            return false;
        } else {
            return true;
        }
    }

    public bool has_prev() {
        if (shuffle) {
            return true;
        } else if (current_index == 0) {
            return false;
        } else {
            return true;
        }
    }

    public uint inc() {
        if (current_index == seq.length - 1) {
            if (repeat) {
                if (shuffle) {
                    create_shuffle_seq();
                    inc();
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

    public uint dec() {
        if (current_index == 0) {
            if (shuffle) {
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

