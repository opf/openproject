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

class Users::ProjectAuthorizationCache
  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def cache(actions)
    Array(actions)
      .flat_map { |action| normalized_permission_names(action) }
      .each do |action|
      allowed_project_ids = Project.allowed_to(user, action).pluck(:id)

      projects_by_actions[action] = allowed_project_ids
    end
  end

  def cached?(action)
    normalized_permission_names(action).all? { |action_name| projects_by_actions.key?(action_name) }
  end

  def allowed?(action, project)
    normalized_permission_names(action).any? { |action_name| projects_by_actions[action_name].include? project.id }
  end

  private

  def normalized_permission_names(action)
    case action
    when Symbol
      [OpenProject::AccessControl.permission(action).name]
    when Hash
      OpenProject::AccessControl.allow_actions(action).map(&:name)
    end
  end

  def projects_by_actions
    @projects_by_actions ||= {}
  end
end
