/*
 * This file is part of tatam.
 * 
 *     tatam is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 * 
 *     tatam is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 * 
 *     You should have received a copy of the GNU General Public License
 *     along with tatam.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright 2018 Takayuki Tanaka
 */

public class TestWindow {
    public static int main(string[] args) {
        TestWindow tester = new TestWindow();
        return tester.do_test();
    }

    public int do_test() {
        Tatam.Options options = Options();
        options.icon_size = 48;
        options.thumbnail_size = 64;
        options.show_thumbs_at = Tatam.ShowThumbsAt.ALBUMS;
        options.ao_type = "pulse";
        options.playlist_image_size = 48;
        options.last_playlist_name = "";
        Tatam.Window window = new Tatam.Window(options);
        
    }
}
