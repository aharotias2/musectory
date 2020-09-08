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
            bus.add_watch(1, handle_message);
            keyboard_input = new IOChannel.unix_new(stdin.fileno());
            keyboard_input.add_watch(IOCondition.IN, handle_keyboard);
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
                debug("message state_changed");
                Gst.State old_state, new_state, pending_state;
                message.parse_state_changed(out old_state, out new_state, out pending_state);
                if (message.src == playbin) {
                    playing_status = new_state;
                    if (new_state == Gst.State.PLAYING) {
                        unpause();
                        unpaused();
                    } else if (new_state == Gst.State.PAUSED) {
                        pause();
                        paused();
                    }
                }
                return true;
            default:
                return true;
            }
        }

        private bool handle_keyboard(IOChannel channel, IOCondition condition) {
            try {
                string line;
                size_t length;
                size_t terminator_pos;
                IOStatus returned_status = channel.read_line(out line, out length, out terminator_pos);
                if (returned_status == IOStatus.NORMAL) {
                    switch (line) {
                    case "q":
                        debug("keyboard q");
                        finished();
                        break;
                    case " ":
                        debug("keyboard space");
                        if (playing_status == Gst.State.PLAYING) {
                            paused();
                        } else {
                            unpaused();
                        }
                        break;
                    }
                }
                return true;
            } catch (ConvertError e) {
                return false;
            } catch (IOChannelError e) {
                return false;
            }
        }

        private void pause() {
            playbin.set_state(Gst.State.PAUSED);
        }

        private void unpause() {
            playbin.set_state(Gst.State.PLAYING);
        }
    }
}
