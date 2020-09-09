using Gst;

namespace Tatam {
    public class GstPlayer : GLib.Object {
        private Element playbin;
        private IOChannel keyboard_input;
        private Gst.State playing_status;
        
        public signal void error_occured(GLib.Error error);
        public signal void finished();
        public signal void paused();
        public signal void unpaused();
        
        public GstPlayer() {
            playing_status = Gst.State.NULL;
            playbin = ElementFactory.make("playbin", "player");
            Gst.Bus bus = playbin.get_bus();
            bus.add_watch(0, handle_message);
        }
        
        public void play(string file_path) {
            debug("start playing");
            playbin.set("uri", "file://" + file_path);
            playbin.set_state(State.PLAYING);
        }

        public void set_position(SmallTime small_time) {
            debug("set position to %u", small_time.milliseconds);
            playbin.seek_simple(Gst.Format.TIME,
                                Gst.SeekFlags.FLUSH | Gst.SeekFlags.KEY_UNIT,
                                small_time.milliseconds * Gst.MSECOND);
        }

        private bool handle_message(Gst.Bus bus, Message message) {
            switch (message.type) {
            case MessageType.ERROR:
                debug("message error");
                GLib.Error error;
                string error_message;
                message.parse_error(out error, out error_message);
                error_occured(error);
                return false;
            case MessageType.EOS:
                debug("message eos");
                playbin.set_state(Gst.State.NULL);
                finished();
                return false;
            case MessageType.STATE_CHANGED:
                if (message.src == playbin) {
                    Gst.State old_state, new_state, pending_state;
                    message.parse_state_changed(out old_state, out new_state, out pending_state);
                    debug("message state_changed from %s to %s", old_state.to_string(), new_state.to_string());
                    if (playing_status != new_state) {
                        playing_status = new_state;
                        if (playing_status == Gst.State.PLAYING) {
                            unpaused();
                        } else if (playing_status == Gst.State.PAUSED) {
                            paused();
                        }
                    }
                }
                return true;
            default:
                return true;
            }
        }

        public void pause() {
            playbin.set_state(Gst.State.PAUSED);
        }

        public void unpause() {
            playbin.set_state(Gst.State.PLAYING);
        }
    }
}
