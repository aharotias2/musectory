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

using Gtk;

namespace Musectory.Dialogs {
    public void show_app_dialog(Window parent_window) {
        var dialog = new AboutDialog();
        dialog.set_destroy_with_parent(true);
        dialog.set_transient_for(parent_window);
        dialog.set_modal(true);
        dialog.artists = {"Takayuki Tanaka<aharotias2@gmail.com>"};
        dialog.authors = {"Takayuki Tanaka<aharotias2@gmail.com>"};
        dialog.documenters = null;
        dialog.translator_credits = "Takayuki Tanaka (ja)<aharotias2@gmail.com>\nAlbano Battistella (it)<albano_battistella@hotmail.com>";
        dialog.program_name = Musectory.PROGRAM_NAME;
        dialog.comments = "Music player with file finder";
        dialog.copyright = "Copyright (C) 2018-2022 Takayuki Tanaka";
        dialog.version = "2.1.0";
        dialog.license =
"""This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.""";
        dialog.wrap_license = true;
        dialog.website = "https://github.com/aharotias2/musectory-player";
        dialog.website_label = "Musectory Player @ Github";
        dialog.logo_icon_name = "com.github.aharotias2.musectory-player";
        dialog.response.connect((response_id) => {
            if (response_id == ResponseType.CANCEL || response_id == ResponseType.DELETE_EVENT) {
                dialog.hide_on_delete();
            }
        });
        dialog.present();
    }

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

    public bool error(string message, Window parent_window) {
        MessageDialog alert_box = new MessageDialog(parent_window, DialogFlags.MODAL,
                MessageType.ERROR, ButtonsType.OK, message);
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
