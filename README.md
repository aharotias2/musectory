# dplayer
Windows's MFPlayer-like music player for GTK-3
## Requirements
* vala
* libgee-1.0
* GTK+-3.18 or later
* MPlayer (runtime only)
## Build
```
cd dplayer
make
```
## Install
```
make install
```
## Other informations
* It uses /tmp/dplayer directory. You should chmod your user name on this directory.
* It creates directory "~/.dplayer" to put configuration and resource files.
## TODO
* Implement functions to edit playlist (move up, move down, remove),
* functions to cache finder view on Gtk.Stack.
* functions to update artwork file if audio file is newer than artwork file.
* ~~functions to save playlists on sidebar on no-CSD mode,~~
* ~~functions to save playlists on sidebar,~~
* ~~Implement Directory Chooser dialog.~~
* ~~A way to switch back to file chooser window from playlist in server side decoration (opposite of CSD) mode.~~
