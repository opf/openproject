#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module MeetingsHelper
  def top_level_sidebar_menu_items
    [
      menu_upcoming_meetings_item,
      menu_past_meetings_item
    ]
  end

  def involvement_sidebar_menu_items
    [
      menu_upcoming_invitations_item,
      menu_past_invitations_item,
      menu_attendee_item,
      menu_creator_item
    ]
  end

  def menu_upcoming_meetings_item
    path = project_or_global_meetings_path

    menu_link_element path, t(:label_upcoming_meetings)
  end

  def menu_past_meetings_item
    path = project_or_global_meetings_path(
      filters: [{ time: { operator: '=', values: ['past'] } }],
      sort: 'start_time:desc'
    )

    menu_link_element path, t(:label_past_meetings)
  end

  def menu_upcoming_invitations_item
    path = project_or_global_meetings_path(
      filters: [
        { time: { operator: '=', values: ['future'] } },
        { invited_user_id: { operator: '=', values: [User.current.id.to_s] } }
      ],
      sort: 'start_time'
    )

    menu_link_element path, t(:label_upcoming_invitations)
  end

  def menu_past_invitations_item
    path = project_or_global_meetings_path(
      filters: [
        { time: { operator: '=', values: ['past'] } },
        { invited_user_id: { operator: '=', values: [User.current.id.to_s] } }
      ],
      sort: 'start_time:desc'
    )

    menu_link_element path, t(:label_past_invitations)
  end

  def menu_attendee_item
    path = project_or_global_meetings_path(
      filters: [{ attended_user_id: { operator: '=', values: [User.current.id.to_s] } }]
    )

    menu_link_element path, t(:label_attendee)
  end

  def menu_creator_item
    path = project_or_global_meetings_path(
      filters: [{ author_id: { operator: '=', values: [User.current.id.to_s] } }]
    )

    menu_link_element path, t(:label_author)
  end

  def project_or_global_meetings_path(filters: nil, sort: nil)
    return polymorphic_path([@project, :meetings]) if filters.blank? && sort.blank?

    query_params = {}.tap do |query|
      query[:filters] = filters.to_json if filters.present?
      query[:sort] = sort if sort.present?
    end

    polymorphic_path([@project, :meetings], query_params)
  end

  def menu_link_element(path, label)
    link_to path, class: menu_item_css_class(path), title: label do
      content_tag(:span, class: 'op-sidemenu--item-title') do
        label
      end
    end
  end

  def menu_item_css_class(path)
    "op-sidemenu--item-action#{menu_item_selected(path) ? ' selected' : ''}"
  end

  def menu_item_selected(menu_item_path)
    menu_item_path == request.fullpath
  end

  def format_participant_list(participants)
    if participants.any?
      user_links = participants
        .sort
        .reject { |p| p.user.nil? }
        .map { |p| link_to_user p.user }

      safe_join(user_links, '; ')
    else
      t('placeholders.default')
    end
  end

  def render_meeting_journal(model, journal, options = {})
    return '' if journal.initial?

    journal_content = render_journal_details(journal, :label_updated_time_by, model, options)
    content_tag 'div', journal_content,  id: "change-#{journal.id}", class: 'journal'
  end

  # This renders a journal entry with a header and details
  def render_journal_details(journal, header_label = :label_updated_time_by, _model = nil, options = {})
    header = <<-HTML
      <div class="profile-wrap">
        #{avatar(journal.user)}
      </div>
      <h4>
        <div class="journal-link" style="float:right;">#{link_to "##{journal.anchor}", anchor: "note-#{journal.anchor}"}</div>
        #{authoring journal.created_at, journal.user, label: header_label}
        #{content_tag('a', '', name: "note-#{journal.anchor}")}
      </h4>
    HTML

    if journal.details.any?
      details = content_tag 'ul', class: 'details journal-attributes' do
        journal.details.map do |detail|
          if d = journal.render_detail(detail, cache: options[:cache])
            content_tag('li', d.html_safe)
          end
        end.compact.join(' ').html_safe
      end
    end

    content_tag('div', "#{header}#{details}".html_safe, id: "change-#{journal.id}", class: 'journal')
  end

  def global_meeting_create_context?
    global_new_meeting_action? || global_create_meeting_action?
  end

  def global_new_meeting_action?
    request.path == new_meeting_path
  end

  def global_create_meeting_action?
    request.path == meetings_path && @project.nil?
  end
end
