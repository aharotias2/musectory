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
				default_outdir = get_default_out_dir();
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
                    info.file_type = DFileType.FILE;
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

		public static bool is_music_file(string file_path) {
			Cli cli = new Cli("mplayer", "-vo", "null", "-ao", "null", "-identify", "-frames", "0", file_path);
			cli.execute();
			return cli.status == 0 && cli.stdout.index_of("ID_AUDIO_ID=") >= 0;
		}

		public static bool contains_music(string dir_path) {
			return false;
		}

		public static string? create_artwork_file(string file_path) {
            DPath path = new DPath(file_path);

            try {
                if (!path.pic_exists) {
                    if (!FileUtils.test(path.tmp_dir, FileTest.EXISTS)) {
                        debug("created a directory: %s", path.tmp_dir);
                        File dir = File.new_for_path(path.tmp_dir);
                        dir.make_directory_with_parents();
                    }
                    Cli cli;
                    cli = new Cli("mplayer", "-ao", "null", "-demuxer", "lavf", "-vo", get_outdir(path.tmp_dir),
                                  "-ss", "00:00:00", "-endpos", "00:00:00", "-frames", "1", file_path);
                    cli.execute();
                    if (cli.status != 0) {
                        stderr.printf("MPlayer.create_artwork_file: %s: mplayer command abnormally ended\n", file_path);
                        stderr.printf("MPlayer.create_artwork_file: pic_file: %s\n", path.pic_file);
                        debug("stderr: %s", cli.stderr);
                        return null;
                    } else {
                        debug("mplayer command has been executed");
                    }

                    path.put_pic_file();
                }

                return path.pic_file;
            } catch (Error e) {
                stderr.printf("ERROR: creating directory was failed: (path: %s)\n", path.tmp_dir);
                return null;
            }
		}
		
		public static Gdk.Pixbuf? get_music_artwork(string pic_file_path, int? size=-1) {
            if (MyUtils.FileUtils.is_empty(pic_file_path)) {
                return null;
            }
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
            DPath path = new DPath.with_index(file_path, index);
            if (!path.pic_exists) {
                path.put_pic_file(index);
                DPath path2 = new DPath(Path.get_dirname(file_path));
                if (MyUtils.FileUtils.is_empty(path2.pic_file)) {
                    File f1 = File.new_for_path(path.pic_file);
                    File f2 = File.new_for_path(path2.pic_file);
                    try {
                        f1.copy(f2, FileCopyFlags.OVERWRITE);
                    } catch (Error e) {
                        stderr.printf("ERROR: It was failed to copy %s to %s", path.pic_file, path2.pic_file);
                    }
                }
			}

			try {
				if (size < 0) {
					return new Gdk.Pixbuf.from_file(path.pic_file);
				} else {
					return new Gdk.Pixbuf.from_file_at_size(path.pic_file, size, size);
				}
			} catch (Error e) {
				FileUtils.remove(path.pic_file);
				debug("get_music_artwork_from_mplayer_output: load %s is failed", path.pic_file);
				return null;
			}
		}

		//--------------------------------------------------------------------------------------
		// プライベートメソッド - MPlayerのメタデータ出力を解析し、DFileInfo型のオブジェクトに
		// セットする。
		//--------------------------------------------------------------------------------------
        public const string TMP_BASE = "/tmp/" + PROGRAM_NAME;
        public const string OUT_DIR = TMP_BASE + "/tmp";
        
        private static string get_default_out_dir() {
            return "/tmp/" + PROGRAM_NAME + "/tmp";
        }
        
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

        private class DPath {

            public string tmp_dir { get { return v_tmp_dir; } }
            public string pic_file { get { return v_pic_file; } }
            public bool pic_exists {
                get {
                    return v_pic_exists;
                }
            }

            public DPath(string file_path) {
                string basename = Path.get_basename(file_path);
                string dirname = Path.get_basename(Path.get_dirname(file_path));
                string filename = dirname + "_" + basename;
                v_pic_file = TMP_BASE + "/" + filename;
                v_tmp_dir = TMP_BASE + "/tmp/" + filename;
                set_pic_exists(file_path);
            }
            
            public DPath.with_index(string file_path, int index) {
                string basename = Path.get_basename(file_path);
                string dirname = Path.get_basename(Path.get_dirname(file_path));
                string filename = dirname + "_" + basename;
                v_pic_file = TMP_BASE + "/" + filename;
                v_tmp_dir = TMP_BASE + "/tmp/";
                set_pic_exists(file_path);
            }
            
            public void set_pic_ext(string extension) {
                if (!v_pic_exists) {
                    v_pic_file = v_pic_file + "." + extension;
                }
            }
            
            private void set_pic_exists(string file_path) {
                v_pic_exists = true;
                if (FileUtils.test(v_pic_file + ".jpg", FileTest.EXISTS)
                    && MyUtils.FileUtils.compare_mtime(v_pic_file + ".jpg", file_path) >= 0) {
                    v_pic_file += ".jpg";
                } else if (FileUtils.test(v_pic_file + ".png", FileTest.EXISTS)
                           && MyUtils.FileUtils.compare_mtime(v_pic_file + ".png", file_path) >= 0) {
                    v_pic_file += ".png";
                } else if (FileUtils.test(v_pic_file + ".jpeg", FileTest.EXISTS)
                           && MyUtils.FileUtils.compare_mtime(v_pic_file + ".jpeg", file_path) >= 0) {
                    v_pic_file += ".jpeg";
                } else {
                    v_pic_exists = false;
                }
            }
            
            private string? get_tmp_pic_path(int index = 1) {
                try {
                    string tmp_file_path = "%s/%08d".printf(v_tmp_dir, index);
                    string ext = ".jpg";
                    string tmp_file_path2 = tmp_file_path + ext;
                    if (!FileUtils.test(tmp_file_path2, FileTest.EXISTS)) {
                        ext = ".jpeg";
                        tmp_file_path2 = tmp_file_path + ext;
                        if (!FileUtils.test(tmp_file_path2, FileTest.EXISTS)) {
                            ext = ".png";
                            tmp_file_path2 = tmp_file_path + ext;
                            if (!FileUtils.test(tmp_file_path2, FileTest.EXISTS)) {
                                MyUtils.FileUtils.create_empty_file(tmp_file_path2);
                            }
                        }
                    }
                    debug("DPath.get_tmp_pic_path found: %s", tmp_file_path2);
                    return tmp_file_path2;
                } catch (Error e) {
                    return null;
                } catch (IOError e) {
                    return null;
                }
            }
            
            public void put_pic_file(int index = 1) {
				string? temp_file_path = get_tmp_pic_path(index);
                if (temp_file_path != null) {
                    string ext = MyUtils.FilePathUtils.extension_of(temp_file_path);
                    set_pic_ext(ext);
                    debug("get_music_artwork_from_mplayer_output: temp_file_path2 = %s, pic_file_path = %s\n", temp_file_path, v_pic_file);
                    FileUtils.rename(temp_file_path, v_pic_file);
                } else {
                    stderr.printf("temp file is not found.\n");
                }
            }
            
            private bool v_pic_exists;
            private string v_tmp_dir;
            private string v_pic_file;
        }
	}
}
