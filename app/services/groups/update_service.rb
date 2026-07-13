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

    former_parent_id = model.detail&.parent_id_in_database

    call = super

    remove_member_roles(member_role_ids)
    cleanup_members(removed_users, project_ids)
    handle_parent_change(former_parent_id)

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

  def member_roles_to_prune(users) # rubocop:disable Metrics/AbcSize
    return MemberRole.none if users.empty?

    user_ids = users.map(&:id)

    direct_ids = MemberRole
      .joins(:member)
      .where(inherited_from: model.members.joins(:member_roles).select("member_roles.id"))
      .where(members: { user_id: user_ids })
      .pluck(:id)

    ancestor_ids = ancestor_member_role_ids_to_prune(users)

    all_ids = (direct_ids + ancestor_ids).uniq
    return MemberRole.none if all_ids.empty?

    MemberRole.joins(:member).where(id: all_ids)
  end

  def ancestor_member_role_ids_to_prune(users)
    model.ancestors.flat_map do |ancestor|
      users_not_in_ancestor = users.reject { |u| ancestor.user_ids.include?(u.id) }
      next [] if users_not_in_ancestor.empty?

      MemberRole
        .joins(:member)
        .where(inherited_from: ancestor.members.joins(:member_roles).select("member_roles.id"))
        .where(members: { user_id: users_not_in_ancestor.map(&:id) })
        .pluck(:id)
    end
  end

  def handle_parent_change(former_parent_id)
    new_parent_id = model.detail&.parent_id
    return if former_parent_id == new_parent_id

    propagate_ancestor_memberships if new_parent_id.present?
    cleanup_former_ancestor_memberships(former_parent_id) if former_parent_id.present?
  end

  def propagate_ancestor_memberships
    group_ids = model.self_and_descendants.pluck(:id)
    user_ids = model.self_and_descendants.flat_map(&:user_ids).uniq
    principal_ids = (user_ids + group_ids).uniq
    return if principal_ids.empty?

    model.ancestors.each do |ancestor|
      Groups::CreateInheritedRolesService
        .new(ancestor, current_user: user)
        .call(user_ids: principal_ids)
    end
  end

  def cleanup_former_ancestor_memberships(former_parent_id) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    former_parent = Group.find_by(id: former_parent_id)
    return unless former_parent

    affected_users = model.self_and_descendants.flat_map(&:users).uniq
    affected_group_ids = model.self_and_descendants.pluck(:id)
    return if affected_users.empty? && affected_group_ids.empty?

    former_parent.self_and_ancestors.each do |ancestor|
      users_not_in_ancestor = affected_users.reject { |u| ancestor.user_ids.include?(u.id) }
      principal_ids_to_clean = users_not_in_ancestor.map(&:id) + affected_group_ids
      next if principal_ids_to_clean.empty?

      role_ids_to_clean = MemberRole
        .joins(:member)
        .where(inherited_from: ancestor.members.joins(:member_roles).select("member_roles.id"))
        .where(members: { user_id: principal_ids_to_clean })
        .pluck(:id)

      next if role_ids_to_clean.empty?

      Groups::CleanupInheritedRolesService
        .new(ancestor, current_user: user)
        .call(member_role_ids: role_ids_to_clean)
    end
  end

  def cleanup_members(users, project_ids)
    Members::CleanupService
      .new(users, project_ids)
      .call
  end
end
