# Tatam
Windows's MFPlayer-like music player for GTK-3
## Requirements
* vala
* libgee-1.0
* gdk-pixbuf
* GTK+-3.18 or later
* MPlayer (runtime only)
## Build
```
cd tatam
make
```
## Install
```
make install
```
## Other informations
* It uses /tmp/tatam directory. You should chmod your user name on this directory.
* It creates directory "~/.tatam" to put configuration and resource files.
## TODO
* functions to cache finder view on Gtk.Stack (if possible).
* ~~functions to update artwork file if audio file is newer than artwork file.~~
* ~~Implement functions to edit playlist (move up, move down, remove),~~
* ~~functions to save playlists on sidebar on no-CSD mode,~~
* ~~functions to save playlists on sidebar,~~
* ~~Implement Directory Chooser dialog.~~
* ~~A way to switch back to file chooser window from playlist in server side decoration (opposite of CSD) mode.~~
