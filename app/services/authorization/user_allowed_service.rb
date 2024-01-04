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

class Authorization::UserAllowedService
  attr_accessor :user

  def initialize(user, role_cache: Users::ProjectRoleCache.new(user))
    self.user = user
    self.project_role_cache = role_cache
  end

  # Return true if the user is allowed to do the specified action on a specific context
  # Action can be:
  # * a parameter-like Hash (eg. { controller: '/projects', action: 'edit' })
  # * a permission Symbol (eg. :edit_project)
  # Context can be:
  # * a project : returns true if user is allowed to do the specified action on this project
  # * a group of projects : returns true if user is allowed on every project
  # * an entity that a user can become a member of specifically (listed in Member::ALLOWED_ENTITIES) :
  #   * returns true if user is allowed to do the specified action on the given item or
  #   * returns ture if user is allowed to do the specified action on the project the entity belongs to
  # * nil with +global+ set to +true+ : check if user has at least one role allowed for this action,
  #   or falls back to Non Member / Anonymous permissions depending if the user is logged
  def call(action, context, global: false)
    if supported_context?(context, global:)
      allowed_to?(action, context, global:)
    else
      false
    end
  end

  def preload_projects_allowed_to(action)
    project_authorization_cache.cache(action)
  end

  private

  attr_accessor :project_role_cache

  def allowed_to?(action, context, global: false)
    action = normalize_action(action)

    if context.nil? && global
      allowed_to_globally?(action)
    elsif context.is_a? Project
      allowed_to_in_project?(action, context)
    elsif supported_entity?(context)
      allowed_to_in_entity?(action, context)
    elsif context.respond_to?(:to_a)
      allowed_to_in_all_projects?(action, context)
    else
      false
    end
  end

  def allowed_to_in_entity?(action, entity)
    # Inactive users are never authorized
    return false unless authorizable_user?

    # Short circuit: When the user is already allowed to execute the action baed
    # on the project, there's no need to do a check on the entity
    return true if entity.respond_to?(:project) && allowed_to_in_project?(action, entity.project)

    # Admin users are authorized for anything else
    # unless the permission is explicitly flagged not to be granted to admins.
    return true if granted_to_admin?(action)

    has_authorized_role?(action, entity)
  end

  def allowed_to_in_project?(action, project)
    return false if project.nil?

    if project_authorization_cache.cached?(action)
      return project_authorization_cache.allowed?(action, project)
    end

    # No action allowed on archived projects
    return false unless project.active? || project.being_archived?
    # No action allowed on disabled modules
    return false unless project.allows_to?(action)
    # Inactive users are never authorized
    return false unless authorizable_user?
    # Admin users are authorized for anything else
    # unless the permission is explicitly flagged not to be granted to admins.
    return true if granted_to_admin?(action)

    has_authorized_role?(action, project)
  end

  # Authorize if user is authorized on every element of the array
  def allowed_to_in_all_projects?(action, projects)
    projects.present? && Array(projects).all? do |project|
      allowed_to?(action, project)
    end
  end

  # Is the user allowed to do the specified action on any project?
  # See allowed_to? for the action parameter description.
  def allowed_to_globally?(action)
    # Inactive users are never authorized
    return false unless authorizable_user?
    # Admin users are always authorized
    return true if granted_to_admin?(action)

    has_authorized_role?(action)
  end

  ##
  # Only users that are not locked may be granted actions
  # with the exception of a temporary-granted system user
  def authorizable_user?
    !user.locked? || user.is_a?(SystemUser)
  end

  # Admin users are granted every permission unless the
  # permission explicitly disables it.
  def granted_to_admin?(action)
    user.admin? && OpenProject::AccessControl.grant_to_admin?(action)
  end

  def has_authorized_role?(action, context = nil)
    project_role_cache
      .fetch(context)
      .any? do |role|
      role.allowed_to?(action)
    end
  end

  def project_authorization_cache
    @project_authorization_cache ||= Users::ProjectAuthorizationCache.new(user)
  end

  def normalize_action(action)
    if action.is_a?(Hash) && action[:controller] && action[:controller].to_s.starts_with?('/')
      action = action.dup
      action[:controller] = action[:controller][1..]
    end

    action
  end

  def supported_context?(context, global:)
    (context.nil? && global) ||
      context.is_a?(Project) ||
      supported_entity?(context) ||
      (!context.nil? && context.respond_to?(:to_a))
  end

  def supported_entity?(entity)
    Member.can_be_member_of?(entity)
  end
end
