#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Projects
  class CopyService < ::BaseServices::Copy

    ##
    # In case a rollback is needed,
    # destroy the copied project again.
    def rollback
      state.project&.destroy
    end

    protected

    ##
    # Whether to skip the given key.
    # Useful when copying nested dependencies
    def skip_dependency?(params, dependency_cls)
      !Copy::Dependency.should_copy?(params, dependency_cls.identifier.to_sym)
    end

    def copy_dependencies
      [
        ::Projects::Copy::MembersDependentService,
        ::Projects::Copy::VersionsDependentService,
        ::Projects::Copy::CategoriesDependentService,
        ::Projects::Copy::WorkPackagesDependentService,
        ::Projects::Copy::WikiDependentService,
        ::Projects::Copy::ForumsDependentService,
        ::Projects::Copy::QueriesDependentService,
        ::Projects::Copy::BoardsDependentService
      ]
    end

    def initialize_copy(source, params)
      target = Project.new
      target.attributes = source.attributes.dup.except(*skipped_attributes)
      # Clear enabled modules
      target.enabled_modules = []
      target.enabled_module_names = source.enabled_module_names - %w[repository]
      target.types = source.types
      target.work_package_custom_fields = source.work_package_custom_fields

      # Copy status object
      target.status = source.status&.dup

      # Copy enabled custom fields and their values
      target.custom_field_values = source.custom_value_attributes
      target.custom_values = source.custom_values.map(&:dup)

      # Additional input target params
      target_project_params = params[:target_project_params].with_indifferent_access

      cleanup_target_project_params(source, target, target_project_params)
      cleanup_target_project_attributes(source, target, target_project_params)

      # Assign additional params from user
      call = Projects::SetAttributesService
        .new(user: user,
             model: target,
             contract_class: Projects::CopyContract,
             contract_options: { copy_source: source })
        .call(target_project_params)

      # Retain values after the set attributes service
      retain_attributes(source, target, target_project_params)

      # Retain the project in the state for other dependent
      # copy services to use
      state.project = target

      call
    end

    def retain_attributes(source, target, target_project_params)
      # Ensure we keep the public value of the source project
      # which might get overridden by the SetAttributesService
      # unless the user provided a different value
      target.public = source.public unless target_project_params.key?(:public)
    end

    def cleanup_target_project_params(_source, _target, target_project_params)
      if (parent_id = target_project_params[:parent_id]) && (parent = Project.find_by(id: parent_id))
        target_project_params.delete(:parent_id) unless user.allowed_to?(:add_subprojects, parent)
      end
    end

    def cleanup_target_project_attributes(source, target, target_project_params)
      if target.parent
        target.parent = nil unless user.allowed_to?(:add_subprojects, target.parent)
      end
    end

    def skipped_attributes
      %w[id created_at updated_at name identifier active lft rgt]
    end
  end
end
