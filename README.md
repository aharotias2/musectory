# Tatam

A simple GTK+3 music player written in vala.

## Requirements

* vala
* gtk+-3.0
* gee-0.8
* gstreamer-1.0

## Build

```
cd tatam
meson --prefix=/usr/local builddir
cd builddir
meson compile
```

## Install

```
sudo meson install
```

## Other informations
* It uses /tmp/tatam directory. You should chmod your user name on this directory.
* It creates directory "~/.tatam" to put configuration and resource files.
