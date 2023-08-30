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

module Authorization
  module_function

  # Returns all users having a certain permission within a project
  def users(action, project)
    Authorization::UserAllowedQuery.query(action, project)
  end

  # Returns all projects a user has a certain permission in
  def projects(action, user)
    Authorization::ProjectQuery.query(user, action)
  end

  # Returns all work packages the user has explicit permission in
  def work_packages(action, user)
    Authorization::WorkPackageQuery.query(user, action)
  end

  # Returns all roles a user has in a certain project, for a specific entity or globally
  def roles(user, context = nil)
    if context.is_a?(Project)
      Authorization::UserProjectRolesQuery.query(user, context)
    elsif Member.can_be_member_of?(context)
      Authorization::UserEntityRolesQuery.query(user, context)
    else
      Authorization::UserGlobalRolesQuery.query(user)
    end
  end
end
