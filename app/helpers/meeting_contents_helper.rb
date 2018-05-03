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
        link_to_if_authorized l(:label_meeting_close),
                              { controller: '/meeting_agendas',
                                action: 'close',
                                meeting_id: meeting },
                              method: :put,
                              data: { confirm: I18n.t(:text_meeting_closing_are_you_sure) },
                              class: 'meetings--close-meeting-button button icon-context icon-locked'
      end
    when 'meeting_minutes'
      content_tag :li, '', class: 'toolbar-item' do
        link_to_if_authorized l(:label_meeting_agenda_close),
                              { controller: '/meeting_agendas',
                                action: 'close',
                                meeting_id: meeting },
                              method: :put,
                              class: 'button icon-context icon-locked'
      end
    end
  end

  def open_meeting_agenda_link(content_type, meeting)
    case content_type
    when 'meeting_agenda'
      content_tag :li, '', class: 'toolbar-item' do
        link_to_if_authorized l(:label_meeting_open),
                              { controller: '/meeting_agendas',
                                action: 'open',
                                meeting_id: meeting },
                              method: :put,
                              class: 'button icon-context icon-unlocked',
                              confirm: l(:text_meeting_agenda_open_are_you_sure)
      end
    when 'meeting_minutes'
    end
  end

  def meeting_content_edit_link(content_type)
    content_tag :li, '', class: 'toolbar-item' do
      content_tag :button,
                  '',
                  class: 'button button--edit-agenda',
                  onclick: "jQuery('.edit-#{content_type}').show();
                            jQuery('.show-#{content_type}').hide();
                            jQuery('.button--edit-agenda').addClass('-active');
                            jQuery('.button--edit-agenda').attr('disabled', true);
                  return false;" do
        link_to l(:button_edit),
                '',
                class: 'icon-context icon-edit',
                accesskey: accesskey(:edit)
      end
    end
  end

  def meeting_content_history_link(content_type, meeting)
    content_tag :li, '', class: 'toolbar-item' do
      link_to_if_authorized l(:label_history),
                            { controller: '/' + content_type.pluralize,
                              action: 'history',
                              meeting_id: meeting },
                            class: 'button icon-context icon-wiki'
    end
  end

  def meeting_content_notify_link(content_type, meeting)
    content_tag :li, '', class: 'toolbar-item' do
      link_to_if_authorized l(:label_notify),
                            { controller: '/' + content_type.pluralize,
                              action: 'notify', meeting_id: meeting },
                            method: :put,
                            class: 'button icon-context icon-mail1'
    end
  end

  def meeting_content_icalendar_link(content_type, meeting)
    content_tag :li, '', class: 'toolbar-item' do
      link_to_if_authorized l(:label_icalendar),
                            { controller: '/' + content_type.pluralize,
                              action: 'icalendar', meeting_id: meeting },
                            method: :put,
                            class: 'button icon-context icon-calendar2'
    end
  end
end
