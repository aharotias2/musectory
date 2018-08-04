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
* It put an icon image onto ~/.icons.
* It put a CSS file onto ~/.config
* And It put a config file onto your HOME directory.
## TODO
* Implement Directory Chooser dialog.
* A way to switch back to file chooser window from playlist in server side decoration (opposite of CSD) mode.
