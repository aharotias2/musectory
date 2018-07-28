/*
 * This file is part of dplayer.
 * 
 *     dplayer is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 * 
 *     dplayer is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 * 
 *     You should have received a copy of the GNU General Public License
 *     along with dplayer.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright 2018 Takayuki Tanaka
 */

using Gtk, DPlayer;

class DPlayerStack : Bin {
    private Stack stack;
    public DPlayerStack(Widget finder, Widget playlist) {
        this.stack = new Stack();
        {
            this.stack.transition_type = StackTransitionType.UNDER_UP;
            this.stack.add_named(finder, "finder");
            this.stack.add_named(playlist, "playlist");
        }
        add(this.stack);
    }
    
    public bool is_visible() {
        return this.stack.visible;
    }

    public void show() {
        this.stack.visible = true;
    }

    public void hide() {
        this.stack.visible = false;
    }

    public bool is_finder_visible() {
        return this.stack.visible_child_name == "finder";
    }

    public bool is_playlist_visible() {
        return this.stack.visible_child_name == "playlist";
    }

    public void show_finder() {
        this.stack.transition_type = StackTransitionType.UNDER_LEFT;
        this.stack.visible_child_name = "finder";
    }

    public void show_playlist() {
        this.stack.transition_type = StackTransitionType.OVER_RIGHT;
        this.stack.visible_child_name = "playlist";
    }
}
