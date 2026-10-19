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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Queries::Principals::Filters::MentionableOnMessageFilter <
  Queries::Principals::Filters::PrincipalFilter
  def allowed_values_subset
    @allowed_values_subset ||= ::Message.visible
  end

  def type
    :list_optional
  end

  def self.key
    :mentionable_on_message
  end

  def human_name
    "mentionable" # Only for Internal use, not visible in the UI
  end

  def apply_to(query_scope)
    case operator
    when "="
      query_scope.where(id: mentionable_principals)
    when "!"
      query_scope.where(id: visible_scope.where.not(id: mentionable_principals.select(:id)))
    end
  end

  private

  def type_strategy
    @type_strategy ||= Queries::Filters::Strategies::HugeList.new(self)
  end

  def mentionable_principals
    visible_scope.where(id: project_members).or(visible_scope.where(id: public_topic_participants))
  end

  # view_messages is a public permission: every member of the project can read its forums.
  def project_members
    Member.of_project(projects).select(:user_id)
  end

  # Participants of a private project's topic who are no longer members can no longer read it.
  def public_topic_participants
    Message
      .where(id: topic_ids).or(Message.where(parent_id: topic_ids))
      .joins(forum: :project).where(projects: { public: true })
      .select(:author_id)
  end

  def topic_ids
    Message.where(id: values).select(Arel.sql("COALESCE(#{Message.table_name}.parent_id, #{Message.table_name}.id)"))
  end

  def visible_scope
    Principal.visible(User.current)
  end

  def projects
    Project.where(id: Forum.where(id: Message.where(id: values).select(:forum_id)).select(:project_id))
  end
end
