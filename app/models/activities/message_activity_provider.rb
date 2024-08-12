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

class Activities::MessageActivityProvider < Activities::BaseActivityProvider
  activity_provider_for type: "messages",
                        permission: :view_messages

  def extend_event_query(query)
    query.join(forums_table).on(activity_journals_table[:forum_id].eq(forums_table[:id]))
  end

  def event_query_projection
    [
      activity_journal_projection_statement(:subject, "message_subject"),
      activity_journal_projection_statement(:content, "message_content"),
      activity_journal_projection_statement(:parent_id, "message_parent_id"),
      projection_statement(forums_table, :id, "forum_id"),
      projection_statement(forums_table, :name, "forum_name"),
      projection_statement(forums_table, :project_id, "project_id")
    ]
  end

  def projects_reference_table
    forums_table
  end

  protected

  def event_title(event)
    "#{event['forum_name']}: #{event['message_subject']}"
  end

  def event_description(event)
    event["message_content"]
  end

  def event_type(event)
    event["parent_id"].blank? ? "message" : "reply"
  end

  def event_path(event)
    url_helpers.topic_path(*url_helper_parameter(event))
  end

  def event_url(event)
    url_helpers.topic_url(*url_helper_parameter(event))
  end

  private

  def forums_table
    @forums_table ||= Forum.arel_table
  end

  def url_helper_parameter(event)
    is_reply = event["parent_id"].present?

    if is_reply
      { id: event["parent_id"], r: event["journable_id"], anchor: "message-#{event['journable_id']}" }
    else
      [event["journable_id"]]
    end
  end
end
