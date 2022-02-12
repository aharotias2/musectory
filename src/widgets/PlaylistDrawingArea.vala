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
using Gtk;
using Cairo;

namespace Musectory {
    public class PlaylistDrawingArea : Bin {
        private DrawingArea area;
        public PlaylistItem.Status status { get; set; }
        public int size { get; set; }
        public RGBA circle_line_color { get; set; }
        public RGBA circle_fill_color { get; set; }
        public RGBA foreground_color { get; set; }
        public uint index { get; set; }
        public bool does_draw_outline { get; set; }
        public double circle_size_percentage { get; set; }
        public double font_size_percentage { get; set; }
        public double pause_height_percentage { get; set; }

        public PlaylistDrawingArea() {
            status = NORMAL;
            size = 64;
            index = 1;
            does_draw_outline = false;
            circle_size_percentage = 0.6;
            font_size_percentage = 0.27;
            pause_height_percentage = 0.27;
            circle_line_color = RGBAUtils.new_rgba_from_string("FFFFFF", 0.7);
            circle_fill_color = RGBAUtils.new_rgba_from_string("FFFFFF", 0.5);
            foreground_color = RGBAUtils.new_rgba_from_string("222222", 0.9);
            area = new DrawingArea();
            {
                area.set_size_request(size, size);
                area.draw.connect(on_draw);
            }
            add(area);
        }

        public void set_area_size(int new_size) {
            size = new_size;
            set_size_request(size, size);
            area.set_size_request(size, size);
        }

        protected bool on_draw(Widget da, Context ctx) {
            draw_circle(da, ctx);
            switch (status) {
              case NORMAL:
                draw_number(da, ctx);
                break;
              case PLAYING:
                draw_playback_icon(da, ctx);
                break;
              case PAUSED:
                draw_pause_icon(da, ctx);
                break;
              case HIDDEN:
            default:
                break;
            }
            return true;
        }

        protected void draw_circle(Widget da, Context ctx) {
            double red = circle_line_color.red;
            double green = circle_line_color.green;
            double blue = circle_line_color.blue;
            double alpha = circle_line_color.alpha;
            int half_size = size / 2;
            ctx.arc(half_size, half_size, half_size * circle_size_percentage, 0.0, 360.0 * (Math.PI / 180.0));
            if (does_draw_outline) {
                ctx.set_source_rgba(red, green, blue, alpha);
                ctx.set_line_width(1.0);
                ctx.stroke_preserve();
            }
            red = circle_fill_color.red;
            green = circle_fill_color.green;
            blue = circle_fill_color.blue;
            alpha = circle_fill_color.alpha;
            ctx.set_source_rgba(red, green, blue, alpha);
            ctx.fill();
        }

        protected void draw_number(Widget da, Context ctx) {
            double red = foreground_color.red;
            double green = foreground_color.green;
            double blue = foreground_color.blue;
            double alpha = foreground_color.alpha;
            TextExtents extents;
            string text = index.to_string();
            ctx.set_font_size(size * font_size_percentage);
            ctx.set_source_rgba(red, green, blue, alpha);
            ctx.text_extents(text, out extents);
            ctx.move_to(size / 2 - extents.width / 2, size / 2 + extents.height / 2);
            ctx.show_text(text);
        }

        protected void draw_playback_icon(Widget da, Context ctx) {
            double red = foreground_color.red;
            double green = foreground_color.green;
            double blue = foreground_color.blue;
            double alpha = foreground_color.alpha;
            int width = (int) (size * 0.3);
            int half_width = width / 2;
            int height = (int) Math.sqrt(width * width - half_width * half_width);
            int x1 = size / 2 - height / 3;
            int y1 = size / 2 - half_width;
            int x2 = size / 2 - height / 3;
            int y2 = size / 2 + half_width;
            int x3 = size / 2 + height / 3 * 2;
            int y3 = size / 2;
            ctx.set_source_rgba(red, green, blue, alpha);
            ctx.move_to(x1, y1);
            ctx.line_to(x2, y2);
            ctx.line_to(x3, y3);
            ctx.close_path();
            ctx.fill();
        }

        protected void draw_pause_icon(Widget da, Context ctx) {
            double red = foreground_color.red;
            double green = foreground_color.green;
            double blue = foreground_color.blue;
            double alpha = foreground_color.alpha;
            int width = (int) (size * 0.1);
            if (size < 40) {
                width = (int) (size * 0.15);
            }
            int height = (int) (size * pause_height_percentage);
            int space = (int) (size * 0.05);
            int half_size = size / 2;
            int half_height = height / 2;
            int half_space = (int) (space / 2.0);
            int x1 = half_size - half_space - width;
            int y1 = half_size - half_height;
            int x3 = half_size + half_space;
            int y3 = y1;
            if (x1 + width >= x3) {
                width = x3 - x1 - 1;
            }
            ctx.set_line_width(0);
            ctx.set_source_rgba(red, green, blue, alpha);
            ctx.rectangle(x1, y1, width, height);
            ctx.fill();
            ctx.rectangle(x3, y3, width, height);
            ctx.fill();
        }
    }
}
