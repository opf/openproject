# frozen_string_literal: true

# -- copyright
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
# ++

class ProjectRole < Role
  # Permissions a role must grant in order to be assignable as the default
  # role for a non-admin user who creates a project. Without these, the
  # creator cannot complete project setup (filling out the PIR, adding
  # members, etc.).
  PERMISSIONS_FOR_PROJECT_CREATOR = %i[
    view_project

    view_project_attributes
    edit_project_attributes

    view_members
    manage_members
  ].freeze

  has_many :custom_fields_roles,
           foreign_key: "role_id",
           dependent: :restrict_with_error,
           inverse_of: :role

  def self.givable
    super
      .where(type: "ProjectRole")
  end

  # Roles eligible to be granted to a non-admin user upon project creation.
  # Restricted to givable roles that include all PERMISSIONS_FOR_PROJECT_CREATOR.
  def self.assignable_to_project_creator
    permissions = PERMISSIONS_FOR_PROJECT_CREATOR.map(&:to_s)

    role_ids = RolePermission
                 .where(permission: permissions)
                 .group(:role_id)
                 .having("COUNT(DISTINCT permission) = ?", permissions.size)
                 .select(:role_id)

    givable.where(id: role_ids)
  end

  # Return the builtin 'non member' role.  If the role doesn't exist,
  # it will be created on the fly.
  def self.non_member
    non_member_role = where(builtin: BUILTIN_NON_MEMBER).first
    if non_member_role.nil?
      non_member_role = create(name: "Non member", position: 0) do |role|
        role.builtin = BUILTIN_NON_MEMBER
      end
      raise "Unable to create the non-member role." if non_member_role.new_record?
    end
    non_member_role
  end

  # Return the builtin 'anonymous' role.  If the role doesn't exist,
  # it will be created on the fly.
  def self.anonymous
    anonymous_role = where(builtin: BUILTIN_ANONYMOUS).first
    if anonymous_role.nil?
      anonymous_role = create(name: "Anonymous", position: 0) do |role|
        role.builtin = BUILTIN_ANONYMOUS
      end
      raise "Unable to create the anonymous role." if anonymous_role.new_record?
    end
    anonymous_role
  end

  def self.in_new_project
    assignable_to_project_creator
      .except(:order)
      .reorder(Arel.sql(
                 "COALESCE(#{Setting.new_project_user_role_id.to_i} = #{quoted_table_name}.id, false) DESC, " \
                 "#{quoted_table_name}.position"
               ))
      .first
  end
end
