/*
 * This file is part of musectory-player.
 *
 *     musectory-player is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     musectory-player is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with musectory-player.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright 2018 Takayuki Tanaka
 */

using Gdk;

namespace Musectory.PixbufUtils {
    public Gdk.Pixbuf scale_limited(Gdk.Pixbuf pixbuf, uint size) {
        size = uint.max(10, size);
        if (pixbuf.width >= pixbuf.height) {
            if (size >= pixbuf.width) {
                return pixbuf.copy();
            } else {
                return pixbuf.scale_simple((int) size,
                                           (int) (size * ((double) pixbuf.height / pixbuf.width)),
                                           Gdk.InterpType.BILINEAR);
            }
        } else {
            if (size >= pixbuf.height) {
                return pixbuf.copy();
            } else {
                return pixbuf.scale_simple((int) ((int) size * ((double) pixbuf.width / pixbuf.height)),
                                           (int) size,
                                           Gdk.InterpType.BILINEAR);
            }
        }
    }

    public Gdk.Pixbuf scale(Gdk.Pixbuf pixbuf, uint size) {
        size = uint.max(10, size);
        if (pixbuf.width >= pixbuf.height) {
            return pixbuf.scale_simple((int) size,
                                       (int) (size * ((double) pixbuf.height / pixbuf.width)),
                                       Gdk.InterpType.BILINEAR);
        } else {
            return pixbuf.scale_simple((int) (size * ((double) pixbuf.width / pixbuf.height)),
                                       (int) size,
                                       Gdk.InterpType.BILINEAR);
        }
    }
}

