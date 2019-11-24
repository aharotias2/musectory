TARGET = mpd
#VALAC_OPTS = -g --save-temps --thread --pkg=posix --pkg=gtk+-3.0 --pkg=json-glib-1.0 -X -lm -D PREPROCESSOR_DEBUG
VALAC_OPTS = --thread --pkg=posix --pkg=gtk+-3.0 --pkg=json-glib-1.0 -X -lm -X -O3
SRC =  Cli.vala Tracker.vala enums.vala DFileInfo.vala MpdOptions.vala MPlayer.vala Finder.vala DFileUtils.vala PlaylistBox.vala MyUtils.vala PlaylistDrawingArea.vala Music.vala MpdStack.vala Text.vala

all: mpd

$(TARGET): $(TARGET).vala $(SRC)
	valac $(VALAC_OPTS) -o $@ $^

test-music: test-music.vala enums.vala Cli.vala DFileInfo.vala MPlayer.vala DFileUtils.vala Music.vala
	valac $(VALAC_OPTS) -o $@ $^

install: $(TARGET)
	[ ! -d ~/.local/bin ] && mkdir ~/.local/bin; cp ./mpd ~/.local/bin; [ ! -d ~/.local/share/icons ] && mkdir ~/.local/share/icons; cp mpd.png ~/.icons; [ ! -d ~/.local/share/applications ] && mkdir -p ~/.local/share/applications; cp mpd.desktop ~/.local/share/applications


