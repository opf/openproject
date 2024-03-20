# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
  def self.givable
    super
      .where(type: 'ProjectRole')
  end

  # Return the builtin 'non member' role.  If the role doesn't exist,
  # it will be created on the fly.
  def self.non_member
    non_member_role = where(builtin: BUILTIN_NON_MEMBER).first
    if non_member_role.nil?
      non_member_role = create(name: 'Non member', position: 0) do |role|
        role.builtin = BUILTIN_NON_MEMBER
      end
      raise 'Unable to create the non-member role.' if non_member_role.new_record?
    end
    non_member_role
  end

  # Return the builtin 'anonymous' role.  If the role doesn't exist,
  # it will be created on the fly.
  def self.anonymous
    anonymous_role = where(builtin: BUILTIN_ANONYMOUS).first
    if anonymous_role.nil?
      anonymous_role = create(name: 'Anonymous', position: 0) do |role|
        role.builtin = BUILTIN_ANONYMOUS
      end
      raise 'Unable to create the anonymous role.' if anonymous_role.new_record?
    end
    anonymous_role
  end

  def self.in_new_project
    givable
      .except(:order)
      .order(Arel.sql("COALESCE(#{Setting.new_project_user_role_id.to_i} = id, false) DESC, position"))
      .first
  end
end
