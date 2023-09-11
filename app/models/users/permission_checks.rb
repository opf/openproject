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

module Users::PermissionChecks
  class UnknownPermissionError < StandardError
    def initialize(permission_name)
      super("Tried to check permission #{permission_name} that is not defined as a valid permission. It will never return true")
    end
  end

  class IllegalPermissionCheck < StandardError
    def initialize(permission, context)
      super("Tried to check permission #{permission.name} in #{context} context. Permissible contexts for this permission are: #{permission.permissible_on.join(', ')}.")
    end
  end

  extend ActiveSupport::Concern

  included do
    delegate :preload_projects_allowed_to, to: :user_allowed_service

    # Some Ruby magic. Create methods for each entity we can have memberships on automatically
    # i.e. allowed_in_work_package? and allowed_in_any_work_package?
    Member::ALLOWED_ENTITIES.each do |entity_model_name|
      entity_name_underscored = entity_model_name.underscore
      entity_class = entity_model_name.constantize

      define_method "allowed_in_#{entity_name_underscored}?" do |permission, entity|
        allowed_in_entity?(permission, entity)
      end

      define_method "allowed_in_any_#{entity_name_underscored}?" do |permission, in_project: nil|
        allowed_in_any_entity?(permission, entity_class, in_project:)
      end
    end
  end

  class_methods do
    def allowed(action, project)
      Authorization.users(action, project)
    end

    def allowed_members(action, project)
      Authorization.users(action, project).where.not(members: { id: nil })
    end
  end

  def reload(*args)
    @user_allowed_service = nil
    @project_role_cache = nil

    super
  end

  # All the new methos to check for permissions. This will completely replace the old interface:
  def allowed_globally?(permission)
    perm = OpenProject::AccessControl.permission(permission)
    raise UnknownPermissionError.new(permission) unless perm
    raise IllegalPermissionCheck.new(perm, :global) unless perm.global?

    user_allowed_service.call(permission, nil, global: false)
  end

  def allowed_in_project?(permission, project)
    perm = OpenProject::AccessControl.permission(permission)
    raise UnknownPermissionError.new(permission) unless perm
    raise IllegalPermissionCheck.new(perm, :project) unless perm.project?

    user_allowed_service.call(permission, project, global: false)
  end

  def allowed_in_any_project?(permission)
    perm = OpenProject::AccessControl.permission(permission)
    raise UnknownPermissionError.new(permission) unless perm
    raise IllegalPermissionCheck.new(perm, :project) unless perm.project?

    user_allowed_service.call(permission, nil, global: true)
  end

  # Return user's roles for project
  def roles_for_project(project)
    project_role_cache.fetch(project)
  end
  alias :roles :roles_for_project

  # Return true if the user is a member of project
  def member_of?(project)
    roles_for_project(project).any?(&:member?)
  end

  # Old allowed_to? interface. Marked as deprecated, should be removed at some point ... Guessing 14.0?

  def allowed_to?(action, context, global: false)
    OpenProject::Deprecation.deprecate_method(User, :allowed_to?)
    user_allowed_service.call(action, context, global:)
  end

  def allowed_to_in_entity?(action, entity)
    OpenProject::Deprecation.replaced(:allowed_to_in_entity?, :allowed_in_entity?, caller)
    allowed_to?(action, entity)
  end

  def allowed_to_in_project?(action, project)
    OpenProject::Deprecation.replaced(:allowed_to_in_project?, :allowed_in_project?, caller)
    allowed_to?(action, project)
  end

  def allowed_to_globally?(action)
    OpenProject::Deprecation.replaced(:allowed_to_globally?, :allowed_globally?, caller)
    allowed_to?(action, nil, global: true)
  end

  private

  def allowed_in_entity?(permission, entity)
    context = entity.model_name.element.to_sym
    perm = OpenProject::AccessControl.permission(permission)
    raise UnknownPermissionError.new(permission) unless perm
    raise IllegalPermissionCheck.new(perm, context) unless perm.permissible_on?(context)

    # TODO: Implement
    puts "Checking if allowed to #{permission} on #{entity}"
  end

  def allowed_in_any_entity?(permission, entity_class, in_project: nil)
    context = entity_class.model_name.element.to_sym
    perm = OpenProject::AccessControl.permission(permission)
    raise UnknownPermissionError.new(permission) unless perm
    raise IllegalPermissionCheck.new(perm, context) unless perm.permissible_on?(context)

    # TODO: Implement
    puts "Checking if allowed to #{permission} on any entity of type #{entity_class}#{" within project #{in_project}" if in_project}"
  end

  def user_allowed_service
    @user_allowed_service ||= ::Authorization::UserAllowedService.new(self, role_cache: project_role_cache)
  end

  def project_role_cache
    @project_role_cache ||= ::Users::ProjectRoleCache.new(self)
  end
end
