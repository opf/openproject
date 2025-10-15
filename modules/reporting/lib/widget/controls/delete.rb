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

class Widget::Controls::Delete < Widget::Controls
  DIALOG_ID = "delete_form"
  private_constant :DIALOG_ID

  option :can_delete, default: -> { false }

  def render_control
    render_popup
  end

  def render?
    @subject.persisted? && can_delete
  end

  private

  def render_popup
    render(
      Primer::Alpha::Dialog.new(
        id: DIALOG_ID,
        title: t(:label_really_delete_question),
        subtitle: nil,
        visually_hide_title: true,
        classes: "DangerDialog",
        role: "alertdialog"
      )
    ) do |dialog|
      dialog.with_show_button(scheme: :invisible) do |button|
        button.with_leading_visual_icon(icon: :trash)

        I18n.t(:button_delete)
      end

      dialog.with_body do
        render Primer::OpenProject::FeedbackMessage.new(
          icon_arguments: { icon: :alert, color: :danger },
          border: false
        ) do |message|
          message.with_heading(tag: :h2) { I18n.t(:label_really_delete_question) }
        end
      end

      dialog.with_footer(show_divider: true) do
        render_popup_buttons
      end
    end
  end

  def render_popup_buttons
    delete_button = render_button(
      scheme: :danger,
      type: :submit,
      formaction: url_for(destroy_url_options),
      formmethod: :delete,
      data: { submit_dialog_id: DIALOG_ID }
    ) do
      I18n.t(:button_delete)
    end

    cancel_button = render_button(data: { close_dialog_id: DIALOG_ID }) do
      I18n.t(:button_cancel)
    end

    safe_join([cancel_button, delete_button])
  end

  def destroy_url_options
    if @subject.project
      { controller: "cost_reports", action: "destroy", id: @subject.id, project_id: @subject.project.id }
    else
      { controller: "cost_reports", action: "destroy", id: @subject.id }
    end
  end
end
