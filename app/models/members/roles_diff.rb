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

class Members::RolesDiff
  attr_reader :user_member, :group_member

  def initialize(user_member, group_member)
    raise ArgumentError unless user_member.project_id == group_member.project_id

    @user_member = user_member
    @group_member = group_member
  end

  def roles_created?
    result == :roles_created
  end

  def roles_updated?
    result == :roles_updated
  end

  def roles_changed?
    result != :roles_unchanged
  end

  def result
    @result ||=
      if user_previous_member_roles_ids.empty?
        :roles_created
      elsif (group_roles_ids - user_previous_member_roles_ids).any?
        :roles_updated
      else
        :roles_unchanged
      end
  end

  private

  def user_previous_member_roles_ids
    Set.new(user_member.member_roles
      .reject { group_member.member_roles.map(&:id).include?(_1.inherited_from) }
      .map(&:role_id).uniq)
  end

  def group_roles_ids
    Set.new(group_member.member_roles.map(&:role_id))
  end
end
