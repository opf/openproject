#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

module MeetingContentsHelper
  def can_edit_meeting_content?(content, content_type)
    authorize_for(content_type.pluralize, 'update') && content.editable?
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
    menu << meeting_content_notify_link(content_type, content.meeting) if saved_meeting_content_text_present?(content)
    menu.join(' ')
  end

  def meeting_agenda_toggle_status_link(content, content_type)
    content.meeting.agenda.present? && content.meeting.agenda.locked? ?
      open_meeting_agenda_link(content_type, content.meeting) :
      close_meeting_agenda_link(content_type, content.meeting)
  end

  def close_meeting_agenda_link(content_type, meeting)
    case content_type
    when 'meeting_agenda'
      link_to_if_authorized l(:label_meeting_close), { controller: '/meeting_agendas', action: 'close', meeting_id: meeting }, method: :put, class: 'icon icon-locked show-meeting_agenda'
    when 'meeting_minutes'
      link_to_if_authorized l(:label_meeting_agenda_close), { controller: '/meeting_agendas', action: 'close', meeting_id: meeting }, method: :put, class: 'icon icon-locked show-meeting_minutes'
    end
  end

  def open_meeting_agenda_link(content_type, meeting)
    case content_type
    when 'meeting_agenda'
      link_to_if_authorized l(:label_meeting_open), { controller: '/meeting_agendas', action: 'open', meeting_id: meeting }, method: :put, class: 'icon icon-unlocked show-meeting_agenda', confirm: l(:text_meeting_agenda_open_are_you_sure)
    when 'meeting_minutes'
    end
  end

  def meeting_content_edit_link(content_type)
    link_to l(:button_edit), '#', class: "icon icon-edit show-#{content_type}", accesskey: accesskey(:edit), onclick: "$$('.edit-#{content_type}').invoke('show'); $$('.show-#{content_type}').invoke('hide'); return false;"
  end

  def meeting_content_history_link(content_type, meeting)
    link_to_if_authorized l(:label_history), { controller: '/' + content_type.pluralize, action: 'history', meeting_id: meeting }, class: "icon icon-wiki show-#{content_type}"
  end

  def meeting_content_notify_link(content_type, meeting)
    link_to_if_authorized l(:label_notify), { controller: '/' + content_type.pluralize, action: 'notify', meeting_id: meeting }, method: :put, class: "icon icon-mail show-#{content_type}"
  end
end
