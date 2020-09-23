# This file is part of tatam.
# 
#     tatam is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
# 
#     tatam is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with tatam.  If not, see <http://www.gnu.org/licenses/>.
# 
# Copyright 2018 Takayuki Tanaka

TARGET = tatam
VALAC_OPTS = --pkg=posix --pkg=gtk+-3.0 --pkg=json-glib-1.0 --pkg=gstreamer-1.0 --pkg=gee-0.8 --pkg=json-glib-1.0 -X -lm -X -O3
SRC =  $(shell find src -name *.vala) 

all: tatam

tatam: src/AppBase.vala src/tatam.vala src/widgets/Controller.vala src/adapters/FileInfoAdapter.vala src/adapters/GstSampleAdapter.vala src/models/FileInfo.vala src/strategy/MetadataReader.vala src/consts/enums.vala src/utils/Dialogs.vala src/utils/PixbufUtils.vala src/utils/FilePathUtils.vala src/consts/IconNames.vala src/consts/StyleClass.vala src/facade/GstPlayer.vala src/atoms/SmallTime.vala src/strategy/DirectoryReader.vala src/consts/Error.vala src/consts/Text.vala src/consts/ProgramName.vala src/utils/Files.vala src/widgets/Finder.vala src/widgets/FinderItem.vala src/consts/Text.vala src/widgets/PlaylistBox.vala src/widgets/PlaylistItem.vala src/widgets/PlaylistDrawingArea.vala src/models/Tracker.vala src/utils/RGBAUtils.vala src/atoms/Hex.vala src/utils/StringUtils.vala src/widgets/Sidebar.vala src/strategy/StringJoiner.vala src/models/Options.vala src/consts/DefaultCss.vala
	valac --pkg=posix --pkg=gtk+-3.0 --pkg=gee-0.8 --pkg=json-glib-1.0 --pkg=gstreamer-1.0 -X -lm -o tatam $^

install: $(TARGET)
	[ ! -d ~/.local/bin ] && mkdir ~/.local/bin; cp ./tatam ~/.local/bin; [ ! -d ~/.local/share/icons ] && mkdir ~/.local/share/icons; cp tatam.png ~/.icons; [ ! -d ~/.local/share/applications ] && mkdir -p ~/.local/share/applications; cp tatam.desktop ~/.local/share/applications

test-music: test-music.vala enums.vala Cli.vala DFileInfo.vala MPlayer.vala DFileUtils.vala Music.vala
	valac $(VALAC_OPTS) -o $@ $^

test-controller: test/test-controller.vala src/widgets/Controller.vala src/consts/Text.vala src/consts/IconNames.vala src/consts/StyleClass.vala src/atoms/SmallTime.vala src/utils/PixbufUtils.vala
	valac -X -lm --pkg=gtk+-3.0 -o build/test/test-controller $^

test-sidebar: test/test-sidebar.vala src/widgets/Sidebar.vala src/consts/enums.vala src/consts/Text.vala src/consts/IconNames.vala src/consts/StyleClass.vala
	valac --pkg=gtk+-3.0 -o build/test/test-sidebar $^

test-small-time: test/test-small-time.vala src/atoms/SmallTime.vala
	valac --pkg=glib-2.0 -o build/test/test-small-time $^

test-metadata: test/test-base.vala test/test-metadata.vala src/strategy/MetadataReader.vala src/consts/Error.vala src/consts/Text.vala src/strategy/DirectoryReader.vala src/atoms/SmallTime.vala src/models/FileInfo.vala src/adapters/FileInfoAdapter.vala src/adapters/GstSampleAdapter.vala src/consts/enums.vala src/utils/FilePathUtils.vala src/consts/ProgramName.vala
	valac --pkg=gdk-3.0 --pkg=posix --pkg=json-glib-1.0 --pkg=gio-2.0 --pkg=glib-2.0 --pkg=gstreamer-1.0 --pkg=gee-0.8 -o build/test/test-metadata $^

test-mimetype: test/test-base.vala test/test-mimetype.vala src/strategy/DirectoryReader.vala src/consts/Error.vala src/consts/Text.vala
	valac --pkg=posix --pkg=gio-2.0 --pkg=glib-2.0 --pkg=gee-0.8 -o build/test/test-mimetype $^

test-gst-player: test/test-gst-player.vala src/widgets/Controller.vala src/adapters/FileInfoAdapter.vala src/adapters/GstSampleAdapter.vala src/models/FileInfo.vala src/strategy/MetadataReader.vala src/consts/enums.vala src/utils/Dialogs.vala src/utils/PixbufUtils.vala src/utils/FilePathUtils.vala src/consts/IconNames.vala src/consts/StyleClass.vala src/facade/GstPlayer.vala src/atoms/SmallTime.vala src/strategy/DirectoryReader.vala src/consts/Error.vala src/consts/Text.vala src/consts/ProgramName.vala
	valac --pkg=posix --pkg=gtk+-3.0 --pkg=gstreamer-1.0 -o build/test/test-gst-player $^


test-finder: test/test-finder.vala src/widgets/Finder.vala src/widgets/FinderItem.vala src/widgets/ImageLoaderThreadData.vala src/models/FileInfo.vala src/consts/enums.vala src/atoms/SmallTime.vala src/consts/IconNames.vala src/consts/Text.vala src/consts/StyleClass.vala src/utils/Files.vala src/utils/FilePathUtils.vala src/utils/PixbufUtils.vala src/strategy/DirectoryReader.vala src/strategy/MetadataReader.vala src/adapters/FileInfoAdapter.vala src/adapters/GstSampleAdapter.vala src/consts/Error.vala src/utils/Dialogs.vala src/consts/ProgramName.vala
	valac --pkg=gee-0.8 --pkg=gtk+-3.0 --pkg=gstreamer-1.0 -o build/test/test-finder $^

test-files: test/test-files.vala src/utils/Files.vala src/consts/enums.vala src/consts/Error.vala src/strategy/DirectoryReader.vala src/models/FileInfo.vala src/adapters/FileInfoAdapter.vala src/atoms/SmallTime.vala src/strategy/MetadataReader.vala src/adapters/GstSampleAdapter.vala src/utils/Dialogs.vala src/consts/Text.vala src/consts/IconNames.vala src/consts/ProgramName.vala
	valac --pkg=json-glib-1.0 --pkg=gee-0.8 --pkg=gtk+-3.0 --pkg=gstreamer-1.0 -o build/test/test-files $^

test-string-joiner: test/test-string-joiner.vala src/strategy/StringJoiner.vala
	valac --pkg=glib-2.0 --pkg=gee-0.8 -o build/test/test-string-joiner $^

test-file-path: test/test-base.vala test/test-file-path.vala src/strategy/DirectoryReader.vala src/consts/Error.vala src/consts/Text.vala src/utils/FilePathUtils.vala src/strategy/StringJoiner.vala src/consts/ProgramName.vala
	valac --pkg=posix --pkg=gio-2.0 --pkg=glib-2.0 --pkg=gee-0.8 -o build/test/test-file-path $^


test-gst-player2: test/test-base.vala test/test-gst-player2.vala src/widgets/Controller.vala src/adapters/FileInfoAdapter.vala src/adapters/GstSampleAdapter.vala src/models/FileInfo.vala src/strategy/MetadataReader.vala src/consts/enums.vala src/utils/Dialogs.vala src/utils/PixbufUtils.vala src/utils/FilePathUtils.vala src/consts/IconNames.vala src/consts/StyleClass.vala src/facade/GstPlayer.vala src/atoms/SmallTime.vala src/strategy/DirectoryReader.vala src/consts/Error.vala src/consts/Text.vala src/consts/ProgramName.vala src/utils/Files.vala
	valac --pkg=posix --pkg=gtk+-3.0 --pkg=gee-0.8 --pkg=json-glib-1.0 --pkg=gstreamer-1.0 -o build/test/test-gst-player2 $^

test-playlist: test/test-base.vala test/test-playlist.vala src/widgets/PlaylistBox.vala src/widgets/PlaylistItem.vala src/widgets/PlaylistDrawingArea.vala src/models/Tracker.vala src/models/FileInfo.vala src/atoms/SmallTime.vala src/consts/enums.vala src/strategy/DirectoryReader.vala src/consts/Error.vala src/consts/Text.vala src/utils/RGBAUtils.vala src/utils/Files.vala src/adapters/FileInfoAdapter.vala src/adapters/GstSampleAdapter.vala src/strategy/MetadataReader.vala src/utils/StringUtils.vala src/consts/StyleClass.vala src/utils/FilePathUtils.vala src/atoms/Hex.vala src/consts/ProgramName.vala src/consts/IconNames.vala src/utils/Dialogs.vala src/utils/PixbufUtils.vala
	valac --pkg=posix --pkg=gtk+-3.0 --pkg=gee-0.8 --pkg=json-glib-1.0 --pkg=gstreamer-1.0 -X -lm -o build/test/test-playlist $^

test-window: $(SRC)
	valac $(VALAC_OPTS) -o build/test/test-window $^


test-gst-player3: test/test-base.vala test/test-gst-player3.vala src/widgets/Controller.vala src/adapters/FileInfoAdapter.vala src/adapters/GstSampleAdapter.vala src/models/FileInfo.vala src/strategy/MetadataReader.vala src/consts/enums.vala src/utils/Dialogs.vala src/utils/PixbufUtils.vala src/utils/FilePathUtils.vala src/consts/IconNames.vala src/consts/StyleClass.vala src/facade/GstPlayer.vala src/atoms/SmallTime.vala src/strategy/DirectoryReader.vala src/consts/Error.vala src/consts/Text.vala src/consts/ProgramName.vala src/utils/Files.vala src/widgets/PlaylistBox.vala src/widgets/PlaylistItem.vala src/widgets/PlaylistDrawingArea.vala src/models/Tracker.vala src/utils/RGBAUtils.vala src/atoms/Hex.vala src/utils/StringUtils.vala
	valac --pkg=posix --pkg=gtk+-3.0 --pkg=gee-0.8 --pkg=json-glib-1.0 --pkg=gstreamer-1.0 -o build/test/test-gst-player3 -X -lm $^


test-gst-player4: test/test-base.vala test/test-gst-player4.vala src/widgets/Controller.vala src/adapters/FileInfoAdapter.vala src/adapters/GstSampleAdapter.vala src/models/FileInfo.vala src/strategy/MetadataReader.vala src/consts/enums.vala src/utils/Dialogs.vala src/utils/PixbufUtils.vala src/utils/FilePathUtils.vala src/consts/IconNames.vala src/consts/StyleClass.vala src/facade/GstPlayer.vala src/atoms/SmallTime.vala src/strategy/DirectoryReader.vala src/consts/Error.vala src/consts/Text.vala src/consts/ProgramName.vala src/utils/Files.vala src/widgets/Finder.vala src/widgets/FinderItem.vala src/consts/Text.vala src/widgets/PlaylistBox.vala src/widgets/PlaylistItem.vala src/widgets/PlaylistDrawingArea.vala src/models/Tracker.vala src/utils/RGBAUtils.vala src/atoms/Hex.vala src/utils/StringUtils.vala src/widgets/Sidebar.vala src/strategy/StringJoiner.vala
	valac --pkg=posix --pkg=gtk+-3.0 --pkg=gee-0.8 --pkg=json-glib-1.0 --pkg=gstreamer-1.0 -X -lm -o build/test/test-gst-player4 $^

