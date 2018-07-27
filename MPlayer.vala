/*
 * This file is part of dplayer.
 * 
 *     dplayer is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 * 
 *     dplayer is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 * 
 *     You should have received a copy of the GNU General Public License
 *     along with dplayer.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright 2018 Takayuki Tanaka
 */

namespace DPlayer {
	public class MPlayer : Object {
		private static string track_name;
		private static string default_outdir;

		private static string get_outdir(string? destdir) {
			return "jpeg:outdir=%s,png:outdir=%s".printf(destdir, destdir);
		}

		public static string quit_command() {
			return "quit\n";
		}

		public static string pause_command() {
			return "pause\n";
		}

		public static string volume_command(double value) {
			return "volume %d 1\n".printf((int) value);
		}

		public static string step_forward_command(uint step) {
			return "pt_step %u\n".printf(step);
		}

		public static string step_backward_command(uint step) {
			return "pt_step -%u\n".printf(step);
		}

		public static string move_pos(int value) {
			return "pausing_keep seek %d 1\n".printf(value);
		}

		public static string[] get_playback_command(ref List<string> file_list, string aotype, bool shuffle, bool repeat) {
			string[] playback_command = {"mplayer", "-novideo", "-slave", "-quiet", "-ao", aotype};
			Array<string> spawn_args_array = new Array<string>();
			spawn_args_array.data = playback_command;
			if (shuffle) {
				spawn_args_array.append_val("-shuffle");
			}
			if (repeat) {
				spawn_args_array.append_val("-loop");
				spawn_args_array.append_val("0");
			}
			foreach(string file_path in file_list) {
				spawn_args_array.append_val(file_path.dup());
			}
			return spawn_args_array.data;
		}

		public static bool when_new_track_started(string mplayer_output) {
			if (mplayer_output.index_of("Playing ") >= 0) {
				// delete "Playing" and trailing "."
				track_name = mplayer_output.slice(8, mplayer_output.length - 2);
				return true;
			} else {
				return false;
			}
		}

		public static bool when_current_track_ended(string mplayer_output) {
			if (mplayer_output.index_of("\n") == 0) {
				track_name = "";
				return true;
			} else {
				return false;
			}
		}

		public static string get_track_name_from_output(string mplayer_output) {
			return track_name;
		}

		public static List<DFileInfo?> get_file_info_and_artwork_list_from_file_list(List<string> file_name_list)
		requires (file_name_list.length() > 0) {
			var info_list = new List<DFileInfo?>();
			if (default_outdir == null) {
				default_outdir = "/tmp/" + program_name + "/tmp";
			}
			Cli cli = new Cli("mplayer", "-ao", "null", "-demuxer", "lavf", "-vo", get_outdir(default_outdir),
							  "-ss", "00:00:00", "-endpos", "0", "-frames", "1", "-identify");
			cli.add_args(file_name_list);
			cli.execute();

			if (cli.status != 0 || cli.stdout.index_of("ID_AUDIO_ID=") < 0) {
				return info_list;
			}

			string[] metadata = cli.stdout.split("\n\n");

			int i = 0;
			int j = 1;
			while (i < metadata.length) {
				string file_path = file_name_list.nth_data(i);
				DFileInfo info = new DFileInfo();
				if (set_file_info_from_mplayer_output(metadata[i + 1], ref info)) {
					info.dir = Path.get_dirname(file_path);
					info.path = file_path;
					info.name = Path.get_basename(file_path);
					if (metadata[i + 1].index_of("output directory:") > 0) {
						info.artwork = get_music_artwork_from_mplayer_output(file_path, j);
						j++;
					}
					info_list.append(info);
				}
				i++;
			}
			return info_list;
		}


        //--------------------------------------------------------------------------------------
		// 楽曲情報取得
		//--------------------------------------------------------------------------------------
		public static bool get_file_info(string file_path, ref DFileInfo info) {
			Cli cli = new Cli("mplayer", "-vo", "null", "-ao", "null", "-identify", "-frames", "0", file_path);
			cli.execute();

			if (cli.status != 0 || cli.stdout.index_of("ID_AUDIO_ID=") < 0) {
				return false;
			}

			string metadata = cli.stdout;

			info.name = file_path.slice(file_path.last_index_of_char('/') + 1, file_path.length);
			info.path = file_path;

			return set_file_info_from_mplayer_output(metadata, ref info);
		}

		/**
		 * 楽曲ファイルかどうかを判断するだけ。
		 */
		public static bool is_music_file(string file_path) {
			Cli cli = new Cli("mplayer", "-vo", "null", "-ao", "null", "-identify", "-frames", "0", file_path);
			cli.execute();
			return cli.status == 0 && cli.stdout.index_of("ID_AUDIO_ID=") >= 0;
		}

		/**
		 * ディレクトリに楽曲ファイルが含まれているかどうかを判別する。
		 */
		public static bool contains_music(string dir_path) {
			return false;
//			var dir_list = new List<
		}

		public static string? create_artwork_file(string file_path) {
			string basename = Path.get_basename(file_path);
			string dirname = Path.get_basename(Path.get_dirname(file_path));
			string filename = dirname + "_" + basename;
			string tmpbase_name = "/tmp/" + program_name;
			string pic_file_path = tmpbase_name + "/" + filename;
			string tmp_dir_path = tmpbase_name + "/tmp/" + filename;
			string ext = "";

			if (FileUtils.test(pic_file_path + ".jpg", FileTest.EXISTS)) {
				pic_file_path += ".jpg";
			} else if (FileUtils.test(pic_file_path + ".png", FileTest.EXISTS)) {
				pic_file_path += ".png";
			} else if (FileUtils.test(pic_file_path + ".jpeg", FileTest.EXISTS)) {
				pic_file_path += ".jpeg";
			} else {
				debug(">>>");
				if (!FileUtils.test(tmp_dir_path, FileTest.EXISTS)) {
					debug("created a directory: %s", tmp_dir_path);
					File dir = File.new_for_path(tmp_dir_path);
					dir.make_directory_with_parents();
				}
				Cli cli;
				cli = new Cli("mplayer", "-ao", "null", "-demuxer", "lavf", "-vo", get_outdir(tmp_dir_path),
							  "-ss", "00:00:00", "-endpos", "00:00:00", "-frames", "1", file_path);
				cli.execute();
				if (cli.status != 0) {
					stderr.printf("MPlayer.create_artwork_file: %s: mplayer command abnormally ended\n", file_path);
					stderr.printf("MPlayer.create_artwork_file: pic_file: %s\n", pic_file_path);
					debug("stderr: %s", cli.stderr);
					return null;
				} else {
					debug("mplayer command has been executed");
				}

				string tmp_file_path = tmp_dir_path + "/00000001";
				ext = ".jpg";
				string tmp_file_path2 = tmp_file_path + ext;
				if (!FileUtils.test(tmp_file_path2, FileTest.EXISTS)) {
					ext = ".jpeg";
					tmp_file_path2 = tmp_file_path + ext;
					if (!FileUtils.test(tmp_file_path2, FileTest.EXISTS)) {
						ext = ".png";
						tmp_file_path2 = tmp_file_path + ext;
						if (!FileUtils.test(tmp_file_path2, FileTest.EXISTS)) {
							stderr.printf("MPlayer.create_artwork_file: command has done but a new file is not created. file name : %s\n",
										  file_path);
							stderr.printf("MPlayer.create_artwork_file: stderr: %s\n", cli.stderr);
							return null;
						}
					}
				}
				pic_file_path = pic_file_path + ext;
				debug("MPlayer.create_artwork_file: tmp_file_path2 = %s, pic_file_path = %s\n", tmp_file_path2, pic_file_path);
				FileUtils.rename(tmp_file_path2, pic_file_path);
				debug("<<<");
			}

			return pic_file_path;
		}

		/*
		public static string? create_artwork_file(string file_path) {
			string[] tmp = file_path.reverse().split("/", 3);
			string pic_file_path = "/tmp/" + program_name + "/" + tmp[1].reverse() + "_" + tmp[0].reverse();
			string ext = "";

			if (FileUtils.test(pic_file_path + ".jpg", FileTest.EXISTS)) {
				pic_file_path += ".jpg";
			} else if (FileUtils.test(pic_file_path + ".png", FileTest.EXISTS)) {
				pic_file_path += ".png";
			} else if (FileUtils.test(pic_file_path + ".jpeg", FileTest.EXISTS)) {
				pic_file_path += ".jpeg";
			} else {
				Cli cli;
				cli = new Cli("mplayer", "-ao", "null", "-demuxer", "lavf", "-vo", get_outdir(),
							  "-ss", "00:00:00", "-endpos", "00:00:00", "-frames", "1", file_path);
				cli.execute();
				if (cli.status != 0) {
					stderr.printf("MPlayer.create_artwork_file: %s: ffmpeg command abnormally ended\n", file_path);
					stderr.printf("MPlayer.create_artwork_file: pic_file: %s\n", pic_file_path);
					return null;
				}

				string temp_file_path = "/tmp/" + program_name + "/tmp/00000001";
				ext = ".jpg";
				string temp_file_path2 = temp_file_path + ext;
				if (!FileUtils.test(temp_file_path2, FileTest.EXISTS)) {
					ext = ".jpeg";
					temp_file_path2 = temp_file_path + ext;
					if (!FileUtils.test(temp_file_path2, FileTest.EXISTS)) {
						ext = ".png";
						temp_file_path2 = temp_file_path + ext;
						if (!FileUtils.test(temp_file_path2, FileTest.EXISTS)) {
							stderr.printf("MPlayer.get_music_artwork: ffmpeg command has done but a new file is not created. file name : %s\n",
										  file_path);
							stderr.printf("MPlayer.get_music_artwork: stderr: %s\n", cli.stderr);
							return null;
						}
					}
				}
				pic_file_path = pic_file_path + ext;
				debug("load_music_artwork: temp_file_path2 = %s, pic_file_path = %s\n", temp_file_path2, pic_file_path);
				FileUtils.rename(temp_file_path2, pic_file_path);
			}

			return pic_file_path;
		}
		*/
		
		public static Gdk.Pixbuf? get_music_artwork(string pic_file_path, int? size=-1) {
			try {
				if (size < 0) {
					return new Gdk.Pixbuf.from_file(pic_file_path);
				} else {
					return new Gdk.Pixbuf.from_file_at_size(pic_file_path, size, size);
				}
			} catch (Error e) {
				FileUtils.remove(pic_file_path);
				stderr.printf("MPlayer.get_music_artwork: load %s is failed\n", pic_file_path);
				return null;
			}
		}

		public static Gdk.Pixbuf? get_music_artwork_from_mplayer_output(string file_path, int index, int? size=-1) {
			string[] tmp = file_path.reverse().split("/", 3);
			string pic_file_path = Path.build_filename("/tmp", program_name, tmp[1].reverse() + "_" + tmp[0].reverse());

			if (FileUtils.test(pic_file_path + ".jpg", FileTest.EXISTS)) {
				pic_file_path += ".jpg";
			} else if (FileUtils.test(pic_file_path + ".png", FileTest.EXISTS)) {
				pic_file_path += ".png";
			} else if (FileUtils.test(pic_file_path + ".jpeg", FileTest.EXISTS)) {
				pic_file_path += ".jpeg";
			} else {
				string temp_file_path = Path.build_filename("/tmp", program_name, "tmp", "%08d".printf(index));
				string ext;
				if (FileUtils.test(temp_file_path + ".jpg", FileTest.EXISTS)) {
					ext = ".jpg";
				} else if (FileUtils.test(temp_file_path + ".png", FileTest.EXISTS)) {
					ext = ".png";
				} else if (FileUtils.test(temp_file_path + ".jpeg", FileTest.EXISTS)) {
					ext = ".png";
				} else {
					debug("get_music_artwork_from_mplayer_output: not found : " + file_path);
					return null;
				}
				pic_file_path = pic_file_path + ext;
				debug("get_music_artwork_from_mplayer_output: temp_file_path2 = %s%s, pic_file_path = %s\n", temp_file_path, ext, pic_file_path);
				FileUtils.rename(temp_file_path + ext, pic_file_path);
			}

			try {
				if (size < 0) {
					return new Gdk.Pixbuf.from_file(pic_file_path);
				} else {
					return new Gdk.Pixbuf.from_file_at_size(pic_file_path, size, size);
				}
			} catch (Error e) {
				FileUtils.remove(pic_file_path);
				debug("get_music_artwork_from_mplayer_output: load %s is failed", pic_file_path);
				return null;
			}
		}

		//--------------------------------------------------------------------------------------
		// プライベートメソッド - MPlayerのメタデータ出力を解析し、DFileInfo型のオブジェクトに
		// セットする。
		//--------------------------------------------------------------------------------------
		private static bool set_file_info_from_mplayer_output(string metadata, ref DFileInfo info) {
			if (metadata != null && metadata != "" && metadata.index_of("ID_AUDIO_ID") > 0) {
				string[] lines = metadata.split("\n", 1000);
				for (int i = 0; i < lines.length; i++) {
					if (lines[i] == "") {
						continue;
					}

					string key;
					string value;

					if (lines[i].index_of("ID_") >= 0) {
						if (lines[i].index_of("ID_CLIP_INFO_NAME") >= 0) {
							key = lines[i].split("=", 2)[1].ascii_down();
							i++;
							value = lines[i].split("=", 2)[1].strip();

							switch (key) {
							case "title":
								info.title = value;
								break;

							case "artist":
								info.artist = value;
								break;

							case "album":
								info.album = value;
								break;

							case "genre":
								info.genre = value;
								break;

							case "comment":
								info.comment = value;
								break;

							case "track":
								info.track = value;
								break;

							case "disc":
								info.disc = value;
								break;

							case "date":
							case "year":
								info.date = value;
								break;
							}
						} else if (lines[i].index_of("ID_LENGTH") >= 0) {
							int val = int.parse(lines[i].split("=", 2)[1].split(".", 2)[0]);
							string time_str;
							if (val > 3600) {
								time_str = "%d:%02d:%02".printf(val / 360, val % 360 / 60, val % 60);
							} else {
								time_str = "%02d:%02d".printf(val /60, val % 60);
							}
							info.time_length = time_str;
						}
					}
				}
				return true;
			} else {
				return false;
			}
		}

	}

}
