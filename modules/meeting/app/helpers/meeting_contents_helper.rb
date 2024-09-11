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

module MeetingContentsHelper
  def can_edit_meeting_content?(content, content_type)
    authorize_for(content_type.pluralize, "update") && content.editable?
  end

  def saved_meeting_content_text_present?(content)
    !content.new_record? && content.text.present? && !content.text.empty?
  end

  def show_meeting_content_editor?(content, content_type)
    can_edit_meeting_content?(content, content_type) && (!saved_meeting_content_text_present?(content) || content.changed?)
  end

  def meeting_content_context_menu(content, content_type)
    menu = []
    menu << meeting_agenda_toggle_status_link(content, content_type)
    menu << meeting_content_edit_link(content_type) if can_edit_meeting_content?(content, content_type)
    menu << meeting_content_history_link(content_type, content.meeting)

    menu.join(" ")
  end

  def meeting_agenda_toggle_status_link(content, content_type)
    if content.meeting.agenda.present? && content.meeting.agenda.locked?
      open_meeting_agenda_link(content_type, content.meeting)
    else
      close_meeting_agenda_link(content_type, content.meeting)
    end
  end

  def close_meeting_agenda_link(content_type, meeting)
    case content_type
    when "meeting_agenda"
      content_tag :li, "", class: "toolbar-item" do
        link_to_if_authorized({ controller: "/meeting_agendas",
                                action: "close",
                                meeting_id: meeting },
                              method: :put,
                              data: { confirm: I18n.t(:text_meeting_closing_are_you_sure) },
                              class: "meetings--close-meeting-button button") do
          text_with_icon(I18n.t(:label_meeting_close), "icon-locked")
        end
      end
    when "meeting_minutes"
      content_tag :li, "", class: "toolbar-item" do
        link_to_if_authorized({ controller: "/meeting_agendas",
                                action: "close",
                                meeting_id: meeting },
                              method: :put,
                              class: "button") do
          text_with_icon(I18n.t(:label_meeting_agenda_close), "icon-locked")
        end
      end
    end
  end

  def open_meeting_agenda_link(content_type, meeting)
    return unless content_type == "meeting_agenda"

    content_tag :li, "", class: "toolbar-item" do
      link_to_if_authorized({ controller: "/meeting_agendas",
                              action: "open",
                              meeting_id: meeting },
                            method: :put,
                            class: "button",
                            data: { confirm: I18n.t(:text_meeting_agenda_open_are_you_sure) }) do
        text_with_icon(I18n.t(:label_meeting_open), "icon-unlocked")
      end
    end
  end

  def meeting_content_edit_link(_content_type)
    content_tag :li, "", class: "toolbar-item" do
      link_to "",
              class: "button button--edit-agenda",
              data: {
                action: "meeting-content#enableEditState",
                "meeting-content-target": "editButton"
              },
              accesskey: accesskey(:edit) do
                text_with_icon(I18n.t(:label_edit), "icon-edit")
              end
    end
  end

  def meeting_content_history_link(content_type, meeting)
    content_tag :li, "", class: "toolbar-item" do
      link_to_if_authorized({ controller: "/" + content_type.pluralize,
                              action: "history",
                              meeting_id: meeting },
                            aria: { label: t(:label_history) },
                            title: t(:label_history),
                            class: "button") do
        text_with_icon(I18n.t(:label_history), "icon-activity-history")
      end
    end
  end

  def text_with_icon(text, icon)
    op_icon("button--icon #{icon}") +
    " " +
    content_tag("span", text, class: "button--text")
  end
end
