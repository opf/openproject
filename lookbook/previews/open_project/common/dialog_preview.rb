# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

module OpenProject
  module Common
    # @hidden
    class DialogPreview < Lookbook::Preview
      # @param button_text
      # @param dialog_title
      # @param dialog_id
      # @param form_id
      def form(button_text: "Show form dialog",
               dialog_title: "Dialog title",
               dialog_id: "dialog-id",
               form_id: "form-id")
        render_with_template(locals: { button_text:, dialog_title:, dialog_id:, form_id: })
      end

      # @param button_text
      # @param dialog_title
      # @param dialog_id
      # @param message
      def confirmation(button_text: "Show confirmation dialog",
                       dialog_title: "Do the action",
                       dialog_id: "dialog-id",
                       message: "Are you sure?")
        render_with_template(locals: { button_text:, dialog_title:, dialog_id:, message: })
      end

      # @param button_text
      # @param dialog_title
      # @param dialog_id
      # @param message
      def confirm_deletion(button_text: "Delete XYZ",
                           dialog_title: "Delete XYZ",
                           dialog_id: "dialog-id",
                           message: "Are you sure you want to delete the item?")
        render_with_template(locals: { button_text:, dialog_title:, dialog_id:, message: })
      end
    end
  end
end
