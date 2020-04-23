#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
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

    if saved_meeting_content_text_present?(content)
      menu << meeting_content_notify_link(content_type, content.meeting)
      menu << meeting_content_icalendar_link(content_type, content.meeting)
    end

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
      content_tag :li, '', class: 'toolbar-item' do
        link_to_if_authorized({ controller: '/meeting_agendas',
                                action: 'close',
                                meeting_id: meeting },
                              method: :put,
                              data: { confirm: I18n.t(:text_meeting_closing_are_you_sure) },
                              class: 'meetings--close-meeting-button button') do
          op_icon('button--icon icon-locked') +
          content_tag('span', l(:label_meeting_close), class: 'button--text')
        end
      end
    when 'meeting_minutes'
      content_tag :li, '', class: 'toolbar-item' do
        link_to_if_authorized({ controller: '/meeting_agendas',
                                action: 'close',
                                meeting_id: meeting },
                              method: :put,
                              class: 'button') do
          op_icon('button--icon icon-locked') +
          content_tag('span', l(:label_meeting_agenda_close), class: 'button--text')
        end
      end
    end
  end

  def open_meeting_agenda_link(content_type, meeting)
    case content_type
    when 'meeting_agenda'
      content_tag :li, '', class: 'toolbar-item' do
        link_to_if_authorized({ controller: '/meeting_agendas',
                                action: 'open',
                                meeting_id: meeting },
                              method: :put,
                              class: 'button',
                              data: { confirm: l(:text_meeting_agenda_open_are_you_sure) }) do
          op_icon('button--icon icon-unlocked') +
          content_tag('span', l(:label_meeting_open), class: 'button--text')
        end
      end
    when 'meeting_minutes'
    end
  end

  def meeting_content_edit_link(content_type)
    content_tag :li, '', class: 'toolbar-item' do
      link_to '',
              class: 'button button--edit-agenda',
              data: { 'content-type': content_type },
              accesskey: accesskey(:edit) do
                op_icon('button--icon icon-edit') +
                content_tag('span', l(:label_edit), class: 'button--text')
              end
    end
  end

  def meeting_content_history_link(content_type, meeting)
    content_tag :li, '', class: 'toolbar-item' do
      link_to_if_authorized({ controller: '/' + content_type.pluralize,
                              action: 'history',
                              meeting_id: meeting },
                            aria: { label: t(:label_history) },
                            title: t(:label_history),
                            class: 'button') do
        op_icon('button--icon icon-wiki') +
        content_tag('span', l(:label_history), class: 'button--text')
      end
    end
  end

  def meeting_content_notify_link(content_type, meeting)
    content_tag :li, '', class: 'toolbar-item' do
      link_to_if_authorized({ controller: '/' + content_type.pluralize,
                              action: 'notify', meeting_id: meeting },
                            method: :put,
                            class: 'button') do
        op_icon('button--icon icon-mail1') +
        content_tag('span', l(:label_notify), class: 'button--text')
      end
    end
  end

  def meeting_content_icalendar_link(content_type, meeting)
    content_tag :li, '', class: 'toolbar-item' do
      link_to_if_authorized({ controller: '/' + content_type.pluralize,
                              action: 'icalendar', meeting_id: meeting },
                            method: :put,
                            class: 'button') do
        op_icon('button--icon icon-calendar2') +
        content_tag('span', l(:label_icalendar), class: 'button--text')
      end
    end
  end
end
