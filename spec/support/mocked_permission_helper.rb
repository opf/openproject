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

# Provides a nice DSL to mock permissions on the user. It also validates that the permissions are
# mocked in the right context. So when you try to mock a project permission globally, it will complain.
# For examples on usage, see spec/support_spec/mocked_permission_helper_spec.rb

class PermissionMock
  attr_reader :user, :permitted_entities, :allow_all_permissions

  NIL_ERROR = "You tried to mock a permission on nil, this will not work! If you want to satisfy the `allow_in_any_project?` call, build an unused project and mock the permission on that.".freeze

  def initialize(user)
    @user = user
    reset_permitted_entities
    @allow_all_permissions = false
  end

  def allow_everything
    @allow_all_permissions = true
  end

  def forbid_everything
    @allow_all_permissions = false
    reset_permitted_entities
  end

  def allow_in_project(*permissions, project:)
    raise ArgumentError, NIL_ERROR if project.nil?

    permissions.each do |permission|
      Authorization.contextual_permissions(permission, :project, raise_on_unknown: true)
    end
    permitted_entities[project] += permissions
  end

  def allow_in_work_package(*permissions, work_package:)
    raise ArgumentError, NIL_ERROR if work_package.nil?

    permissions.each do |permission|
      Authorization.contextual_permissions(permission, :work_package, raise_on_unknown: true)
    end
    permitted_entities[work_package] += permissions
  end

  def allow_in_project_query(*permissions, project_query:)
    raise ArgumentError, NIL_ERROR if project_query.nil?

    permissions.each do |permission|
      Authorization.contextual_permissions(permission, :project_query, raise_on_unknown: true)
    end
    permitted_entities[project_query] += permissions
  end

  def allow_globally(*permissions)
    permissions.each do |permission|
      Authorization.contextual_permissions(permission, :global, raise_on_unknown: true)
    end
    permitted_entities[:global] += permissions
  end

  private

  def reset_permitted_entities
    @permitted_entities = Hash.new do |hash, entity_project_or_global|
      hash[entity_project_or_global] = Array.new
    end
  end
end

module MockedPermissionHelper
  def mock_permissions_for(user) # rubocop:disable Metrics/PerceivedComplexity
    permission_mock = PermissionMock.new(user)

    raise ArgumentError, "You must provide a block." unless block_given?

    yield permission_mock

    # Instead of mocking directly on the user, we mock on the UserPermissibleService
    # Advantage is that we can handle the `allowed_in_entity?` calls correctly without needing to write
    # a mock for each of them

    permissible_service = user.send(:user_permissible_service) # access the private instance

    # Permission is allowed globally, when it has been given globally
    allow(permissible_service).to receive(:allowed_globally?) do |permission_or_action|
      next true if permission_mock.allow_all_permissions

      permissions = Authorization.permissions_for(permission_or_action).map(&:name)
      permission_mock.permitted_entities[:global].intersect?(permissions)
    end

    # Permission allowed on one (or more) projects, when it has been given to all of them
    allow(permissible_service).to receive(:allowed_in_project?) do |permission_or_action, project_or_projects|
      next true if permission_mock.allow_all_permissions

      projects = Array(project_or_projects)
      permissions = Authorization.permissions_for(permission_or_action).map(&:name)

      projects.all? do |project|
        permission_mock.permitted_entities[project].intersect?(permissions)
      end
    end

    # Permission allowed on any project, if it has been given to any project
    allow(permissible_service).to receive(:allowed_in_any_project?) do |permission_or_action|
      next true if permission_mock.allow_all_permissions

      permissions = Authorization.permissions_for(permission_or_action).map(&:name)

      permission_mock.permitted_entities
        .select { |k, _| k.is_a?(Project) }
        .values
        .flatten
        .intersect?(permissions)
    end

    # Permission is allowed on any entity, if
    #   - filtering for one specific project, when
    #     - the permission has been given to that project
    #     - the permission has been given to any work package belonging to that project
    #   - NOT filtering for one specific project, when
    #     - the permission has been given to any project
    #     - the permission has been given to any entity
    allow(permissible_service).to receive(:allowed_in_any_entity?) do |permission_or_action, entity_class, in_project:|
      next true if permission_mock.allow_all_permissions

      permissions = Authorization.permissions_for(permission_or_action).map(&:name)

      next true if in_project && permission_mock.permitted_entities[in_project].intersect?(permissions)

      filtered_entities = if in_project
                            permission_mock.permitted_entities.select do |k, _|
                              k.is_a?(entity_class) && k.respond_to?(:project) && k.project == in_project
                            end
                          else
                            permission_mock.permitted_entities.select { |k, _| k.is_a?(entity_class) || k.is_a?(Project) }
                          end

      filtered_entities
        .values
        .flatten
        .intersect?(permissions)
    end

    # Permission is allowed on a specific entity, if
    #  - the permission has been given to the project the entity belongs to
    #  - the permission has been given to the entity itself
    allow(permissible_service).to receive(:allowed_in_entity?) do |permission_or_action, entity|
      next true if permission_mock.allow_all_permissions

      permissions = Authorization.permissions_for(permission_or_action).map(&:name)

      (entity.respond_to?(:project) && permission_mock.permitted_entities[entity.project].intersect?(permissions)) ||
      permission_mock.permitted_entities[entity].intersect?(permissions)
    end
  end
end

RSpec.configure do |config|
  config.include MockedPermissionHelper
end
