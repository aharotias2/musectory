# dplayer
Windows MFPlayer-like music player for GTK-3
## Requirements
### Build-Time Depencencies
* vala
* libgee-1.0
### Runtime Depencencies
* MPlayer
* GTK+-3.18 or later
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
