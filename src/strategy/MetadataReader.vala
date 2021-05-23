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

using Gst;

namespace Moegi {
    public class MetadataReader : GLib.Object {
        private static int count;

        private Pipeline pipeline;
        private Element uridecoder;
        private Element fakesink;

        public signal bool tag_found(string tag, GLib.Value? value);

        public MetadataReader() {
            count++;
            pipeline = new Pipeline("metadata-pipeline" + count.to_string());
            uridecoder = ElementFactory.make("uridecodebin", "uridecoder");
            pipeline.add(uridecoder);
            fakesink = ElementFactory.make("fakesink", "sink");
            pipeline.add(fakesink);
            uridecoder.pad_added.connect((pad) => {
                Pad sinkpad = fakesink.get_static_pad("sink");
                if (!sinkpad.is_linked()) {
                    if (pad.link(sinkpad) != PadLinkReturn.OK) {
                        debug("Pad link failed\n");
                    } else {
                        debug("Pad link succeeded\n");
                    }
                }
            });
        }

        public SmallTime get_duration() {
            int64 time_in_nanoseconds;
            if (pipeline.query_duration(Gst.Format.TIME, out time_in_nanoseconds)) {
                int time_in_milliseconds = (int) (time_in_nanoseconds / 1000000);
                SmallTime time = new SmallTime.from_milliseconds(time_in_milliseconds);
                return time;
            } else {
                stderr.printf("could not query duration\n");
                return new SmallTime(0);
            }
        }

        public void get_metadata(string file_path) throws Moegi.Error, GLib.Error {
            GLib.File file = GLib.File.new_for_path(file_path);

            if (!file.query_exists()) {
                throw new Moegi.Error.FILE_DOES_NOT_EXISTS(_("File does not exists (%s)\n"), file_path);
            }

            if (!file.query_info("standard::*", 0).get_content_type().has_prefix("audio")) {
                throw new Moegi.Error.FILE_IS_NOT_AN_AUDIO(_("File is not an audio file (%s)\n"), file_path);
            }

            uridecoder.set("uri", "file://" + file_path);
            pipeline.set_state(State.PAUSED);
            debug("pipeline state: PAUSED");
            Gst.Bus bus = pipeline.get_bus();
            bool terminated = false;
            int try_count = 0;
            try {
                while (!terminated) {
                    if (try_count++ >= 10) {
                        stderr.printf("Tried over 10 times exit.\n");
                        return;
                    }
                    MessageType flags = MessageType.ASYNC_DONE | MessageType.TAG | MessageType.ERROR | MessageType.EOS;
                    Message? message = bus.timed_pop_filtered(CLOCK_TIME_NONE, flags);
                    if (message != null) {
                        switch (message.type) {

                          case MessageType.EOS:
                            debug("Gst message (EOS)");
                            terminated = true;
                            break;

                          case MessageType.ASYNC_DONE:
                            debug("Gst message (ASYNC_DONE)");
                            terminated = true;
                            break;

                          case MessageType.ERROR:
                            debug("Gst message (ERROR)");
                            GLib.Error error;
                            message.parse_error(out error, null);
                            throw new Moegi.Error.GST_MESSAGE_ERROR(error.message);

                          case MessageType.TAG:
                            debug("Gst message (TAG)");
                            TagList tag_list;
                            message.parse_tag(out tag_list);
                            tag_list.foreach((tag_list_each, tag) => {
                                if (!terminated) {
                                    uint num = tag_list_each.get_tag_size(tag);
                                    for (uint i = 0; i < num; i++) {
                                        GLib.Value value;
                                        value = tag_list_each.get_value_index(tag, i);
                                        bool response = tag_found(tag, value);
                                        if (!response) {
                                            terminated = true;
                                            break;
                                        }
                                    }
                                }
                            });
                            GLib.Value duration_value = GLib.Value(typeof(Moegi.SmallTime));
                            duration_value.set_object(get_duration());
                            tag_found("duration", duration_value);
                            return;

                        default:
                            debug("Gst message unknown (%s)", message.type.get_name());
                            break;

                        }
                    }
                }
            } finally {
                pipeline.set_state(State.NULL);
                debug("pipeline state: NULL");
            }
        }
    }
}
