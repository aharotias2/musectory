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
