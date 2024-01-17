#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Authorization::UserEntityRolesQuery < Authorization::UserRolesQuery
  transformations.register :all, :user_restriction do |statement, user, _|
    statement.where(users_table[:id].eq(user.id))
  end

  transformations.register users_members_join, :entity_restriction do |statement, _, entity|
    statement = statement
      .and(members_table[:entity_type].eq(entity.class.to_s))
      .and(members_table[:entity_id].eq(entity.id))

    statement = statement.and(members_table[:project_id].eq(entity.project_id)) if entity.respond_to?(:project_id)

    statement
  end
end
