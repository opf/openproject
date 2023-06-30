# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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

# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Metrics/AbcSize
class ActivePermissions::Updater
  include AfterCommitEverywhere

  class << self
    def prepare(change)
      if executed_directly?
        new_singleton.execute(force: true)
      else
        new_singleton.register_change(change)
      end
    end

    def execute_directly
      @executed_directly = true

      yield
    ensure
      @executed_directly = false
    end

    def release_singleton
      RequestStore.delete(:prepared_active_permission_update)
    end

    private

    def executed_directly?
      @executed_directly ||= false
    end

    def new_singleton
      RequestStore.fetch(:prepared_active_permission_update) do
        new
      end
    end
  end

  def register_change(model)
    register_change_for(model)

    register_callback
  end

  def execute(force: false)
    self.class.release_singleton

    # During migrations, we don't want the table to be updated if it does not exist yet.
    return unless ActiveRecord::Base.connection.table_exists?('active_permissions')

    if force
      reinitialize.execute
    elsif (reinitialize_update = changes.detect { |change| change.is_a?(ActivePermissions::Updates::Reinitialize) })
      # In case any changes calls for reinitializing, we do only that as it subsumes the rest.
      reinitialize_update.execute
    else
      changes.compact.each(&:execute)
    end
  end

  private

  def register_callback
    @register_callback ||= before_commit { execute }
  end

  def changes
    @changes ||= []
  end

  def register_change_for(model)
    case model
    when Member
      update_for_member(model)
    when RolePermission
      update_for_role_permission(model)
    when User
      update_for_user(model)
    when Project
      update_for_project(model)
    when EnabledModule
      update_for_enabled_module(model)
    when MemberRole
      update_for_member_role(model)
    end
  end

  def update_for_member(member)
    if member.destroyed? && member.project
      new_or_registered_change(ActivePermissions::Updates::RemoveByProjectMember, member.user_id)
    elsif member.destroyed? && member.project.nil?
      new_or_registered_change(ActivePermissions::Updates::RemoveByGlobalMember, member.user_id)
    elsif member.persisted? && member.project
      new_or_registered_change(ActivePermissions::Updates::CreateByProjectMember, member.id)
    elsif member.persisted? && member.project.nil?
      new_or_registered_change(ActivePermissions::Updates::CreateByGlobalMember, member.id)
    end
  end

  def update_for_role_permission(role_permission)
    if role_permission.destroyed? && role_permission.role.is_a?(GlobalRole)
      new_or_registered_change(ActivePermissions::Updates::RemoveByGlobalPermission, role_permission.permission)
    elsif role_permission.destroyed? && role_permission.role.member?
      new_or_registered_change(ActivePermissions::Updates::RemoveProjectRolePermission, role_permission.permission)
    elsif role_permission.destroyed? && role_permission.role.builtin?
      new_or_registered_change(ActivePermissions::Updates::RemoveBuiltinRolePermission, role_permission.permission)
    elsif role_permission.role.is_a?(GlobalRole)
      new_or_registered_change(ActivePermissions::Updates::CreateByGlobalPermission, role_permission.permission)
    else
      new_or_registered_change(ActivePermissions::Updates::CreateByProjectPermission, role_permission.permission)
    end
  end

  def update_for_user(user)
    # No destroyed users will be received as the user model only has an after_save callback.
    # Destruction is carried out via the association.
    if user.locked? && user.status_previously_changed?
      new_or_registered_change(ActivePermissions::Updates::RemoveByUser, user.id)
    elsif user.admin? && user.admin_previously_changed?
      new_or_registered_change(ActivePermissions::Updates::CreateByAdminUser, user.id)
    elsif !user.admin? && user.admin_previously_changed?
      new_or_registered_change(ActivePermissions::Updates::RemoveByFormerAdminUser, user.id)
    elsif user.active? && user.status_previously_changed?
      new_or_registered_change(ActivePermissions::Updates::CreateByUser, user.id)
    end
  end

  def update_for_project(project)
    if !project.destroyed? && project.active
      new_or_registered_change(ActivePermissions::Updates::CreateByProject, project.id)
    end
  end

  def update_for_enabled_module(enabled_module)
    if enabled_module.destroyed?
      new_or_registered_change(ActivePermissions::Updates::RemoveEnabledModule, enabled_module)
    else
      new_or_registered_change(ActivePermissions::Updates::CreateByProject, enabled_module.project_id)
    end
  end

  def update_for_member_role(member_role)
    if !member_role.destroyed? && member_role.role.is_a?(GlobalRole)
      new_or_registered_change(ActivePermissions::Updates::CreateByGlobalPermission, member_role.role.permissions)
    elsif !member_role.destroyed?
      new_or_registered_change(ActivePermissions::Updates::CreateByProjectPermission, member_role.role.permissions)
    elsif member_role.destroyed? && member_role.role.is_a?(GlobalRole)
      new_or_registered_change(ActivePermissions::Updates::RemoveByGlobalPermission, member_role.role.permissions)
    elsif member_role.destroyed?
      new_or_registered_change(ActivePermissions::Updates::RemoveByProjectPermission, member_role.role.permissions)
    end
  end

  def reinitialize
    ActivePermissions::Updates::Reinitialize.new
  end

  def new_or_registered_change(klass, param)
    if (existing_change = changes.find { |c| c.is_a?(klass) }) && existing_change.respond_to?(:add)
      existing_change.add(param)
    else
      changes << klass.new(param)
    end
  end
end
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/AbcSize
