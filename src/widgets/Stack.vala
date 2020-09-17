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

using Gtk, Tatam;

namespace Tatam {
    class Stack : Bin {
        public enum State {
            SHOW_FINDER, SHOW_PLAYLIST, HIDDEN
        }
        private Gtk.Stack stack;

        public signal void finder_is_selected();
        public signal void playlist_is_selected();

        private State state_value;

        public State state {
            get {
                return state_value;
            }

            set {
                switch (state_value = value) {
                case State.SHOW_FINDER:
                    this.stack.transition_type = StackTransitionType.UNDER_LEFT;
                    this.stack.visible_child_name = "finder";
                    finder_is_selected();
                    break;
                case State.SHOW_PLAYLIST:
                    this.stack.transition_type = StackTransitionType.OVER_RIGHT;
                    this.stack.visible_child_name = "playlist";
                    playlist_is_selected();
                    break;
                }
            }
        }
        
        public Stack() {
            this.state_value = State.SHOW_FINDER;
            this.stack = new Gtk.Stack();
            {
                this.stack.transition_type = StackTransitionType.UNDER_UP;
            }

            add(this.stack);
        }

        public void add_named(Widget widget, string name) {
            this.stack.add_named(widget, name);
        }
    
        public bool stack_is_visible() {
            return this.stack.visible;
        }

        public void show_stack() {
            this.stack.visible = true;
        }

        public void hide_stack() {
            this.stack.visible = false;
        }

        public bool finder_is_visible() {
            return this.state == State.SHOW_FINDER;
        }

        public bool playlist_is_visible() {
            return this.state = State.SHOW_PLAYLIST;
        }

        public void show_finder() {
            this.state = State.SHOW_FINDER;
         }

        public void show_playlist() {
            this.state = State.PLAYLIST;
        }
    }
}