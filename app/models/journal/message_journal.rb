#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class Journal::MessageJournal < Journal::BaseJournal
  self.table_name = "message_journals"

  acts_as_activity_provider type: 'messages',
                            permission: :view_messages

  def self.extend_event_query(j, ej, query)
    b = Arel::Table.new(:boards)

    query = query.join(b).on(ej[:board_id].eq(b[:id]))
    [b, query]
  end

  def self.event_query_projection(j, ej)
    b = Arel::Table.new(:boards)

    [
      ej[:subject].as('message_subject'),
      ej[:content].as('message_content'),
      ej[:parent_id].as('message_parent_id'),
      b[:id].as('board_id'),
      b[:name].as('board_name'),
      b[:project_id].as('project_id')
    ]
  end

  def self.format_event(event, event_data)
    event.title = self.event_title event_data
    event.description event_data['message_content']
    event.type = self.event_type event_data
    event.url = self.event_url event_data

    event
  end

  private

  def self.event_title(event)
    "#{event['board_name']}: #{event['message_subject']}"
  end

  def self.event_type(event)
    event['parent_id'].blank? ? 'message' : 'reply'
  end

  def self.event_url(event)
    is_reply = !event['parent_id'].blank?

    if is_reply
      parameters = { id: event['journable_id'] }
    else
      parameters = { id: event['parent_id'], r: event['journable_id'], anchor: "message-#{event['journable_id']}" }
    end

    parameters[:board_id] = event['board_id']

    Rails.application.routes.url_helpers.topc_path(parameters)
  end
end
