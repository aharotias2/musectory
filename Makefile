TARGET = tatam
VALAC_OPTS = --thread --pkg=posix --pkg=gtk+-3.0 --pkg=json-glib-1.0 -X -lm -X -O3
SRC =  Cli.vala Tracker.vala enums.vala DFileInfo.vala TatamOptions.vala MPlayer.vala Finder.vala DFileUtils.vala PlaylistBox.vala MyUtils.vala PlaylistDrawingArea.vala Music.vala TatamStack.vala Text.vala

all: tatam

$(TARGET): $(TARGET).vala $(SRC)
	valac $(VALAC_OPTS) -o $@ $^

test-music: test-music.vala enums.vala Cli.vala DFileInfo.vala MPlayer.vala DFileUtils.vala Music.vala
	valac $(VALAC_OPTS) -o $@ $^

install: $(TARGET)
	[ ! -d ~/.local/bin ] && mkdir ~/.local/bin; cp ./tatam ~/.local/bin; [ ! -d ~/.local/share/icons ] && mkdir ~/.local/share/icons; cp tatam.png ~/.icons; [ ! -d ~/.local/share/applications ] && mkdir -p ~/.local/share/applications; cp tatam.desktop ~/.local/share/applications
