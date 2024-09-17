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

class Authorization::AbstractUserQuery < Authorization::AbstractQuery
  transformations.register :all,
                           :users_members_join do |statement|
    statement
      .outer_join(members_table)
      .on(users_members_join)
  end

  transformations.register :all,
                           :member_roles_join,
                           after: [:users_members_join] do |statement|
    statement.outer_join(member_roles_table)
             .on(members_member_roles_join)
  end

  def self.members_member_roles_join
    members_table[:id].eq(member_roles_table[:member_id])
  end

  def self.users_members_join
    users_table[:id].eq(members_table[:user_id])
  end

  def self.members_table
    Member.arel_table
  end

  def self.users_table
    User.arel_table
  end

  def self.member_roles_table
    MemberRole.arel_table
  end

  def self.roles_table
    Role.arel_table
  end

  def self.role_permissions_table
    RolePermission.arel_table
  end
end
