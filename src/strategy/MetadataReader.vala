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
 * Copyright 2020 Takayuki Tanaka
 */

using Gst;

namespace Tatam {
    public class MetadataReader : GLib.Object {
        private Pipeline pipeline;
        private Element uridecoder;
        private Element fakesink;

        public signal bool tag_found(string tag, GLib.Value? value);
        
        public MetadataReader() {
            pipeline = new Pipeline("metadata-pipeline");
            uridecoder = ElementFactory.make("uridecodebin", "uridecoder");
            pipeline.add(uridecoder);
            fakesink = ElementFactory.make("fakesink", "sink");
            pipeline.add(fakesink);
            uridecoder.pad_added.connect((pad) => {
                    Pad sinkpad = fakesink.get_static_pad("sink");
                    if (!sinkpad.is_linked()) {
                        if (pad.link(sinkpad) != PadLinkReturn.OK) {
                            stderr.printf("Pad link failed\n");
                        } else {
                            stdout.printf("Pad link succeeded\n");
                        }
                    }
                });
        }

        public SmallTime get_duration() {
            uint64 time_in_nanoseconds;
            if (pipeline.query_duration(Gst.Format.TIME, out time_in_nanoseconds)) {
                uint time_in_milliseconds = (uint) (time_in_nanoseconds / 1000000);
                SmallTime time = new SmallTime.from_milliseconds(time_in_milliseconds);
                return time;
            } else {
                stderr.printf("could not query duration\n");
                return new SmallTime(0);
            }
        }
        
        public void get_metadata(string file_path) throws Tatam.Error, GLib.Error {
            GLib.File file = GLib.File.new_for_path(file_path);

            if (!file.query_exists()) {
                throw new Tatam.Error.FILE_DOES_NOT_EXISTS(Text.ERROR_FILE_DOES_NOT_EXISTS, file_path);
            }

            if (!file.query_info("standard::*", 0).get_content_type().has_prefix("audio")) {
                throw new Tatam.Error.FILE_IS_NOT_AN_AUDIO(Text.ERROR_FILE_IS_NOT_AN_AUDIO, file_path);
            }

            uridecoder.set("uri", "file://" + file_path);
            pipeline.set_state(State.PAUSED);
            debug("pipeline state: PAUSED");
            Gst.Bus bus = pipeline.get_bus();
            bool terminated = false;

            try {
                while (!terminated) {
                    MessageType flags = MessageType.ASYNC_DONE | MessageType.TAG | MessageType.ERROR;
                    Message? message = bus.timed_pop_filtered(CLOCK_TIME_NONE, flags);
                    if (message != null) {
                        switch (message.type) {

                        case MessageType.ASYNC_DONE:
                            debug("Gst message (ASYNC_DONE)");
                            terminated = true;
                            break;

                        case MessageType.ERROR:
                            debug("Gst message (ERROR)");
                            GLib.Error error;
                            message.parse_error(out error, null);
                            throw new Tatam.Error.GST_MESSAGE_ERROR(error.message);

                        case MessageType.TAG:
                            debug("Gst message (TAG)");
                            TagList tag_list;
                            message.parse_tag(out tag_list);
                            tag_list.foreach((tag_list_each, tag) => {
                                    if (!terminated) {
                                        uint num = tag_list_each.get_tag_size(tag);
                                        for (int i = 0; i < num; i++) {
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
                            GLib.Value duration_value = GLib.Value(typeof(Tatam.SmallTime));
                            duration_value.set_object(get_duration());
                            tag_found("duration", duration_value);
                            return;

                        default:
                            debug("Gst message unknown (%s)", message.type.get_name());
                            break;

                        }
                    } else {
                        debug("Gst null message");
                    }
                }
            } finally {
                pipeline.set_state(State.NULL);
                debug("pipeline state: NULL");
            }
        }
    }
}
