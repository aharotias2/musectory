TARGET = tatam
VALAC_OPTS = --thread --pkg=posix --pkg=gtk+-3.0 --pkg=json-glib-1.0 -X -lm -X -O3
SRC =  $(shell find src -name *.vala) 

all: tatam

$(TARGET): $(SRC)
	valac $(VALAC_OPTS) -o build/$(TARGET) $^

install: $(TARGET)
	[ ! -d ~/.local/bin ] && mkdir ~/.local/bin; cp ./tatam ~/.local/bin; [ ! -d ~/.local/share/icons ] && mkdir ~/.local/share/icons; cp tatam.png ~/.icons; [ ! -d ~/.local/share/applications ] && mkdir -p ~/.local/share/applications; cp tatam.desktop ~/.local/share/applications

test-music: test-music.vala enums.vala Cli.vala DFileInfo.vala MPlayer.vala DFileUtils.vala Music.vala
	valac $(VALAC_OPTS) -o $@ $^

test-controller: test/test-controller.vala src/widgets/Controller.vala src/consts/Text.vala src/consts/IconNames.vala src/consts/StyleClass.vala src/atoms/SmallTime.vala
	valac -X -lm --pkg=gtk+-3.0 -o build/test/test-controller $^

test-sidebar: test/test-sidebar.vala src/widgets/Sidebar.vala src/consts/enums.vala src/consts/Text.vala src/consts/IconNames.vala src/consts/StyleClass.vala
	valac --pkg=gtk+-3.0 -o build/test/test-sidebar $^

test-small-time: test/test-small-time.vala src/atoms/SmallTime.vala
	valac --pkg=glib-2.0 -o build/test/test-small-time $^

test-metadata: test/test-metadata.vala src/strategy/MetadataReader.vala src/consts/Error.vala src/consts/Text.vala src/strategy/DirectoryReader.vala src/atoms/SmallTime.vala src/models/FileInfo.vala src/adapters/FileInfoAdapter.vala src/consts/enums.vala
	valac --pkg=gdk-3.0 --pkg=posix --pkg=json-glib-1.0 --pkg=gio-2.0 --pkg=glib-2.0 --pkg=gstreamer-1.0 --pkg=gee-0.8 -o build/test/test-metadata $^

test-files: test/test-files.vala src/strategy/DirectoryReader.vala src/consts/Error.vala src/consts/Text.vala
	valac --pkg=posix --pkg=gio-2.0 --pkg=glib-2.0 -o build/test/test-files $^

test-gst-player: test/test-gst-player.vala src/widgets/Controller.vala src/adapters/FileInfoAdapter.vala src/models/FileInfo.vala src/strategy/MetadataReader.vala src/consts/enums.vala src/utils/PixbufUtils.vala src/consts/IconNames.vala src/consts/StyleClass.vala src/facade/GstPlayer.vala src/atoms/SmallTime.vala src/strategy/DirectoryReader.vala src/consts/Error.vala src/consts/Text.vala
	valac --pkg=posix --pkg=gtk+-3.0 --pkg=gstreamer-1.0 -o build/test/test-gst-player $^

