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
errordomain CLIError {
    EXIT_ABNORMAL
}

class Cli {
    List<string> command_list;
    int exit_status;
    string cli_output;
    string cli_error;

    public string stdout {
        get { return cli_output; }
    }

    public string stderr {
        get { return cli_error; }
    }

    public int status {
        get { return exit_status; }
    }

    public Cli(string command, ...) {
        var valist = va_list();
        command_list = new List<string>();
        command_list.append(command);
        for (string? str = valist.arg<string?>(); str != null; str = valist.arg<string?>()) {
            command_list.append(str);
        }
    }

    public void add_args(List<string> args) {
        foreach(string arg in args) {
            command_list.append(arg);
        }
    }

    public string execute() {
        string[] list = new string[command_list.length()];
        for (int i = 0; i < command_list.length(); i++) {
            list[i] = command_list.nth_data(i);
        }
        try {
            Process.spawn_sync("/", list, Environ.get(), SpawnFlags.SEARCH_PATH, null, out cli_output, out cli_error, out exit_status);
            return cli_error;

        } catch(SpawnError e) {
            // とりあえず異常な値を入れておく。
            exit_status = 1024;
            return "";
        }
    }
}
