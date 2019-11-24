/*
 * This file is part of mpd.
 * 
 *     mpd is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 * 
 *     mpd is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 * 
 *     You should have received a copy of the GNU General Public License
 *     along with mpd.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright 2018 Takayuki Tanaka
 */

namespace Mpd {
	class Music : Object {
		public bool playing {get; set;}
		public bool paused {get; set;}
		public string? current_track_file {get; private set;}
        public signal void on_start(int track_number, string file_path);
        public signal void on_end(int track_number, string file_path);
        public signal void on_quit(Pid pid, int status);
        
		private int current_track_number;
		public int get_current_track_number() { return current_track_number; }

		private uint id_childwatch;
		private Pid child_pid;
		private int fd_stdin;
		private int fd_stdout;
		private IOChannel pipe_in;
		private IOChannel pipe_out;

		private bool playlist_changed;
		private List<string> file_list;
		private string ao_type;
		private bool restarting;
		private bool shuffle;
		private bool repeat;

		//--------------------------------------------------------------------------------
		// Constructor
		//--------------------------------------------------------------------------------

		public Music() {
			restarting = false;
			playlist_changed = false;
			playing = false;
			paused = false;
			fd_stdin = -1;
			fd_stdout = -1;
			current_track_number = -1;
			current_track_file = "";
			shuffle = false;
			repeat = false;
			debug("Music init end");
		}

		//--------------------------------------------------------------------------------
		// Private Methods
		//--------------------------------------------------------------------------------

		public void start(ref List<string> file_list, string ao_type)
		requires (file_list.length() > 0) {
			if (this.file_list != file_list) {
				this.file_list = file_list.copy_deep((src) => { return src.dup(); });
			} 
			this.ao_type = ao_type;
			debug("ao_type -> %s", this.ao_type);
			string[] mplayer_command = MPlayer.get_playback_command(ref this.file_list, this.ao_type, shuffle, repeat);

#if PREPROCESSOR_DEBUG
			for (int i = 0; i < mplayer_command.length; i++) {
				debug("playback command -> %s", mplayer_command[i]);
			}
#endif
		    try {
				Process.spawn_async_with_pipes("/",
											   mplayer_command,
											   Environ.get(),
											   SpawnFlags.SEARCH_PATH | SpawnFlags.DO_NOT_REAP_CHILD,
											   null,
											   out child_pid,
											   out fd_stdin,
											   out fd_stdout,
											   null);

                debug("10");
				id_childwatch = ChildWatch.add(child_pid, _on_quit);
				pipe_in = new IOChannel.unix_new(fd_stdin);
				pipe_out = new IOChannel.unix_new(fd_stdout);
				pipe_out.set_encoding(null);
				pipe_out.add_watch(IOCondition.IN | IOCondition.HUP, on_get_output);
				playing = true;
				paused = false;
				debug("music start (child pid: %d, fd_stdin: %d, fd_stdout: %d)", child_pid, fd_stdin, fd_stdout);
			} catch (Error e) {
				stderr.printf("Process.spawn_async_with_pipes: ERROR");
			}
		}

		public void pause() {
			debug("pause command was called");
			send_mplayer_command(MPlayer.pause_command());
			paused = !paused;
		}

		public void play_next(int step = 1) {
			debug("next command was called");
			send_mplayer_command(MPlayer.step_forward_command(step));
		}

		public void play_prev(int step = 1) {
			debug("prev command was called.");
			send_mplayer_command(MPlayer.step_backward_command(step));
		}

		public void move_pos(int pos_in_percent) {
			debug("move_pos command was called");
			send_mplayer_command(MPlayer.move_pos(pos_in_percent));
		}

		public void quit() {
			debug("quit command was called.");
			send_mplayer_command(MPlayer.quit_command());
		}

		public void set_volume(double value) {
			debug("set_volume command was called %0.0f", value);
			send_mplayer_command(MPlayer.volume_command((int)value));
		}

		public void set_file_list(ref List<string> file_list) {
			playlist_changed = true;
			this.file_list = file_list.copy_deep((src) => { return src.dup(); });
			debug("set file list command was called. file_list.length => %u", this.file_list.length());
		}

		public void restart_playlist(int start_pos, string ao_type) {
			if (start_pos < 0 || file_list.length() <= start_pos) {
				debug("restart_playlist failed. start_pos is out of range (%d/%u)", start_pos, file_list.length());
				return;
			}

			debug("restart playlist command was called (current: %d, new: %d)", current_track_number, start_pos);

			this.ao_type = ao_type;

			if (playlist_changed) {
				if (playing) {
					quit();
				}
				Idle.add(() => {
						if (!playing) {
							debug("*music restart from %d, ao_type: %s", start_pos, this.ao_type);
							start(ref file_list, this.ao_type);
							if (start_pos > 0) {
								play_next(start_pos);
							}
							return Source.REMOVE;
						} else {
							return Source.CONTINUE;
						}
					});
				playlist_changed = false;
			} else {
				int step = start_pos - current_track_number;
				if (step > 0) {
					send_mplayer_command(MPlayer.step_forward_command(step));
				} else if (step < 0) {
					send_mplayer_command(MPlayer.step_backward_command(step.abs()));
				}
			}
		}

		public void toggle_shuffle() {
			shuffle = !shuffle;
			playlist_changed = true;
		}

		public void toggle_repeat() {
			repeat = !repeat;
			playlist_changed = true;
		}

		//--------------------------------------------------------------------------------
		// Private Methods
		//--------------------------------------------------------------------------------

		private void send_mplayer_command(string mplayer_command)
		requires (pipe_in != null) {
			try {
				size_t len;
				pipe_in.write_chars(mplayer_command.to_utf8(), out len);
				pipe_in.flush();
				debug("mplayer command finished (%s) (fd_stdin: %d).", mplayer_command.chomp(), fd_stdin);
			} catch (ConvertError e) {
				stderr.printf("send_mplayer_command: ConvertError. (%s)", e.message);
				return;
			} catch (IOChannelError e) {
				stderr.printf("esnd_mplayer_command: IOChannelError (%s)", e.message);
				return;
			}
		}

		private void _on_quit(Pid pid, int status) {
			Process.close_pid(pid);
			Source.remove(id_childwatch);
			try {
				pipe_in.shutdown(false);
				pipe_out.shutdown(false);
				pipe_in = null;
				pipe_out = null;
				fd_stdin = -1;
				fd_stdout = -1;
			} catch (IOChannelError e) {
				stderr.printf("failed to exit child process. IO connection to child process is currupted.");
				Process.exit(1);
			}

			current_track_number = -1;
			current_track_file = "";
			playing = false;
			paused = false;
			on_quit(pid, status);

			debug("music on quit func ended.");
		}

		private bool on_get_output(IOChannel source, IOCondition condition) {
			if (condition == IOCondition.HUP) {
				return false;
			}

			string mplayer_response;

			try {
				pipe_out.read_line(out mplayer_response, null, null);
				debug("mplayer: %s", mplayer_response.chomp());
			} catch (ConvertError e) {
				debug("mplayer: ConvertError occured (" + e.message + ")");
				return true;
			} catch (IOChannelError e) {
				stderr.printf("IO channel to child process (mplayer) is currupted. program abnormally end.");
				Process.exit(1);
			}

			if (mplayer_response == null) {
				return false;
			}

			if (MPlayer.when_new_track_started(mplayer_response)) {
				debug("new track start");
				current_track_file = MPlayer.get_track_name_from_output(mplayer_response).dup();
				set_current_track_number();
                on_start(current_track_number, current_track_file);
				debug("start playing %s. childwatch id = %u. stdin fd = %d, stdout fd = %d",
					  current_track_file, id_childwatch, fd_stdin, fd_stdout);
			}
	
			//if (playing && current_track_number >= 0 && MPlayer.when_current_track_ended(mplayer_response)) {
            if (MPlayer.when_current_track_ended(mplayer_response)) {
				debug("current track ended");
                on_end(current_track_number, current_track_file);
				if (playlist_changed) {
					restart_playlist(current_track_number + 1, this.ao_type);
					playlist_changed = false;
				}
			}

			return true;
		}

		private void set_current_track_number() {
			for (int i = 0; i < file_list.length(); i++) {
				if (current_track_file.collate(file_list.nth_data(i)) == 0) {
					current_track_number = i;
					debug("set current_track_number = %d", current_track_number);
					return;
				}
			}
		}

#if PREPROCESSOR_DEBUG
		public void debug_print_current_playlist() {
		  for (int i = 0; i < file_list.length(); i++) {
			  debug("%smusic current playlist[%d]: %s", i == current_track_number ? "*":"", i, file_list.nth_data(i));
			}
		}
#endif
	}
}
