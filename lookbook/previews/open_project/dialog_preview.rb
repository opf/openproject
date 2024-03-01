# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2024 the OpenProject GmbH
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
  # @logical_path OpenProject/Common
  class DialogPreview < Lookbook::Preview
    ##
    # **Form dialogs**
    # ---------------------
    # Within the OpenProject application, forms are oftentimes rendered within a dialog. It is used e.g. for
    # the creation of new models or for the modification of existing ones.
    #
    # Form dialogs consist of a header, a body where the form is rendered in and a footer with the buttons to submit
    # or cancel the action.
    #
    # The primer specification [suggests a pattern](/lookbook/inspect/primer/alpha/dialog/with_form) for rendering such dialogs.
    # It consists of a form spanning both the body as well as the footer of the dialog. This has the drawback of the footer
    # potentially being rendered outside of the dialog. That behaviour is undesirable. Primer defines to cope with longer
    # content by scrolling the body.
    #
    # In order for this to happen the form should only be rendered inside the body. The submit button can be logically put inside
    # the form via the `form` attribute.
    #
    # @param button_text
    # @param dialog_title
    # @param dialog_id
    # @param form_id
    def form(button_text: 'Show form dialog',
             dialog_title: 'Dialog title',
             dialog_id: 'dialog-id',
             form_id: 'form-id')
      render_with_template(locals: { button_text:, dialog_title:, dialog_id:, form_id: })
    end
  end
end
