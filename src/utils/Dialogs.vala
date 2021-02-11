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

using Gtk;

namespace Tatam.Dialogs {
    public bool confirm(string message, Window parent_window) {
        MessageDialog m = new MessageDialog(parent_window,
                DialogFlags.MODAL, MessageType.WARNING, ButtonsType.OK_CANCEL, message);
        ResponseType result = (ResponseType)m.run ();
        m.close ();
        return result == ResponseType.OK;
    }

    public bool alert(string message, Window parent_window) {
        MessageDialog alert_box = new MessageDialog(parent_window, DialogFlags.MODAL,
                MessageType.WARNING, ButtonsType.OK, message);
        ResponseType result = (ResponseType)alert_box.run ();
        alert_box.close ();
        return result == ResponseType.OK;
    }

    public string? choose_file(Window parent_window) {
        string? file_path = null;
        var file_chooser = new FileChooserDialog(_("Open File"), parent_window,
                FileChooserAction.OPEN,
                _("_Cancel"), ResponseType.CANCEL,
                _("_Open"), ResponseType.ACCEPT);
        if (file_chooser.run () == ResponseType.ACCEPT) {
            file_path = file_chooser.get_filename();
        }
        file_chooser.destroy ();
        return file_path;
    }

    public string? choose_directory(Window parent_window) {
        string? dir_name = null;
        var file_chooser = new FileChooserDialog (_("Open File"), parent_window,
                FileChooserAction.SELECT_FOLDER,
                _("_Cancel"), ResponseType.CANCEL,
                _("_Open"), ResponseType.ACCEPT);
        if (file_chooser.run () == ResponseType.ACCEPT) {
            dir_name = file_chooser.get_filename();
        }
        file_chooser.destroy ();
        return dir_name;
    }
}
