# frozen_string_literal: true

#-- copyright
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
#++

class Widget::Controls::SaveAs < Widget::Controls
  DIALOG_ID = "save_as_form"
  private_constant :DIALOG_ID

  option :can_save_as, default: -> { false }
  option :can_save_as_public, default: -> { false }

  def render_control
    concat(
      render_button(
        id: "query-icon-save-as",
        data: { show_dialog_id: DIALOG_ID }
      ) do |button|
        button.with_leading_visual_icon(icon: :"op-save")

        button_text
      end
    )

    concat render_popup
  end

  def render?
    can_save_as
  end

  private

  def render_popup
    render(Primer::Alpha::Dialog.new(id: DIALOG_ID, title: button_text)) do |dialog|
      dialog.with_header(variant: :large)

      dialog.with_body do
        render_popup_form
      end

      dialog.with_footer(show_divider: true) do
        render_popup_buttons
      end
    end
  end

  def render_popup_form
    can_save_as_public = self.can_save_as_public
    name = @subject.name

    render_inline_form(form) do |form|
      form.text_field name: :query_name,
                      scope_name_to_model: false,
                      value: name,
                      label: Query.human_attribute_name(:name),
                      required: true

      if can_save_as_public
        form.check_box name: :query_is_public,
                       scope_name_to_model: false,
                       value: "1",
                       checked: false,
                       include_hidden: false,
                       label: Query.human_attribute_name(:public)
      end
    end
  end

  def render_popup_buttons
    save_url_params = { action: "create" }
    save_url_params[:project_id] = @subject.project.id if @subject.project

    save_button = render_button(
      scheme: :primary,
      id: "query-icon-save-button",
      data: { target: url_for(**save_url_params) }
    ) do |button|
      button.with_leading_visual_icon(icon: :check)

      I18n.t(:button_save)
    end

    cancel_button = render_button(data: { close_dialog_id: DIALOG_ID }) do
      I18n.t(:button_cancel)
    end

    safe_join([cancel_button, save_button])
  end

  def button_text
    if @subject.new_record?
      I18n.t(:button_save)
    else
      I18n.t(:button_save_report_as)
    end
  end
end
