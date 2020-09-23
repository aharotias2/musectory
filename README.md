# Tatam
Windows's MFPlayer-like music player for GTK-3
## Requirements
* vala
* gtk+-3.0
* gee-0.8
* json-glib-1.0
* gstreamer-1.0
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
