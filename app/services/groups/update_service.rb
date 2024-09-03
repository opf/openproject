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

class Groups::UpdateService < BaseServices::Update
  protected

  def persist(call)
    removed_users = groups_removed_users(call.result)
    member_roles = member_roles_to_prune(removed_users)
    project_ids = member_roles.pluck(:project_id)
    member_role_ids = member_roles.pluck(:id)

    call = super

    remove_member_roles(member_role_ids)
    cleanup_members(removed_users, project_ids)

    call
  end

  def after_perform(call)
    new_user_ids = call.result.group_users.select(&:saved_changes?).map(&:user_id)

    if new_user_ids.any?
      db_call = ::Groups::AddUsersService
                  .new(call.result, current_user: user)
                  .call(ids: new_user_ids)

      call.add_dependent!(db_call)
    end

    call
  end

  def groups_removed_users(group)
    group.group_users.select(&:marked_for_destruction?).filter_map(&:user)
  end

  def remove_member_roles(member_role_ids)
    ::Groups::CleanupInheritedRolesService
      .new(model, current_user: user)
      .call(member_role_ids:)
  end

  def member_roles_to_prune(users)
    return MemberRole.none if users.empty?

    MemberRole
      .includes(member: :member_roles)
      .where(inherited_from: model.members.joins(:member_roles).select("member_roles.id"))
      .where(members: { user_id: users.map(&:id) })
  end

  def cleanup_members(users, project_ids)
    Members::CleanupService
      .new(users, project_ids)
      .call
  end
end
