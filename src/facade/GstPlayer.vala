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

using Gst;

namespace Tatam {
    public class GstPlayer : GLib.Object {
        private Element playbin;
        private Gst.State playing_status;
        private double volume_value;
        
        public signal void error_occured(GLib.Error error);
        public signal void started();
        public signal void finished();
        public signal void paused();
        public signal void unpaused();
        
        public GstPlayer() {
            volume_value = 0.5;
            init();
        }

        private void init() {
            playing_status = Gst.State.NULL;
            playbin = ElementFactory.make("playbin", "player");
            debug("GstPlayer init ok");
        }
        
        public void play(string file_path) {
            if (playing_status == State.PLAYING) {
                quit();
            }
            debug("start playing");
            init();
            playbin.set("uri", "file://" + file_path);
            playbin.set("volume", volume_value);
            Gst.Bus bus = playbin.get_bus();
            bus.add_watch(0, handle_message);
            playing_status = State.PLAYING;
            playbin.set_state(playing_status);
            started();
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
                playing_status = State.NULL;
                playbin.set_state(playing_status);
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
            debug("GstPlayer.pause was invoked");
            playing_status = State.PAUSED;
            playbin.set_state(playing_status);
        }

        public void unpause() {
            debug("GstPlayer.unpause was invoked");
            playing_status = State.PLAYING;
            playbin.set_state(playing_status);
        }

        public void quit() {
            debug("GstPlayer.quit was invoked");
            playing_status = State.NULL;
            playbin.set_state(playing_status);
        }

        public double volume {
            get {
                return volume_value;
            }
            set {
                debug("GstPlayer.set_volume was invoked");
                if (value < 0) {
                    volume_value = 0.0;
                } else if (value > 1.0) {
                    volume_value = 1.0;
                } else {
                    volume_value = value;
                }
                playbin.set("volume", volume_value);
            }
        }
    }
}
