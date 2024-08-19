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

module Projects
  class CopyService < ::BaseServices::Copy
    include Projects::Concerns::NewProjectService

    def self.copy_dependencies
      [
        ::Projects::Copy::MembersDependentService,
        ::Projects::Copy::VersionsDependentService,
        ::Projects::Copy::CategoriesDependentService,
        ::Projects::Copy::WorkPackagesDependentService,
        ::Projects::Copy::WikiDependentService,
        ::Projects::Copy::ForumsDependentService,
        ::Projects::Copy::QueriesDependentService,
        ::Projects::Copy::BoardsDependentService,
        ::Projects::Copy::OverviewDependentService,
        ::Projects::Copy::StoragesDependentService
      ]
    end

    # Project Folders and File Links aren't dependent services anymore,
    #  so we need to amend the services for the form Representer
    def self.copyable_dependencies
      super + [{ identifier: "storage_project_folders",
                 name_source: -> { I18n.t(:label_project_storage_project_folder) },
                 count_source: ->(source, _) { source.storages.count } },

               { identifier: "file_links",
                 name_source: -> { I18n.t("projects.copy.work_package_file_links") },
                 count_source: ->(source, _) { source.work_packages.joins(:file_links).count("file_links.id") } }]
    end

    protected

    ##
    # Whether to skip the given key.
    # Useful when copying nested dependencies
    def skip_dependency?(params, dependency_cls)
      !Copy::Dependency.should_copy?(params, dependency_cls.identifier.to_sym)
    end

    def set_attributes_params(_params)
      attributes = source_attributes.merge(
        # Clear enabled modules
        enabled_module_names: source_enabled_modules,
        types: source_types,
        work_package_custom_fields: source_custom_fields
      )

      only_allowed_parent_id(attributes)
        .merge(source_custom_field_attributes)
        .merge(target_project_params)
    end

    def before_perform(params, service_call)
      super.tap do |super_call|
        # Retain values after the set attributes service
        retain_attributes(source, super_call.result)

        # Retain the project in the state for other dependent
        # copy services to use
        state.project = super_call.result
      end
    end

    def after_perform(call)
      super.tap do |super_call|
        copy_activated_custom_fields(super_call)
      end
    end

    def copy_activated_custom_fields(call)
      call.result.project_custom_field_ids = source.project_custom_field_ids
    end

    def contract_options
      { copy_source: source, validate_model: true }
    end

    def retain_attributes(source, target)
      # Ensure we keep the public value of the source project
      # which might get overridden by the SetAttributesService
      # unless the user provided a different value
      target.public = source.public unless target_project_params.key?(:public)
    end

    def skipped_attributes
      %w[id created_at updated_at name identifier active templated lft rgt]
    end

    def source_attributes
      source.attributes.dup.except(*skipped_attributes).with_indifferent_access
    end

    def source_enabled_modules
      source.enabled_module_names - %w[repository]
    end

    def source_status
      source.status&.attributes
    end

    def source_types
      source.types
    end

    def source_custom_fields
      source.work_package_custom_fields
    end

    def source_custom_field_attributes
      source
        .custom_value_attributes
        .transform_keys { |key| "custom_field_#{key}" }
    end

    # Additional input target params
    def target_project_params
      params[:target_project_params].with_indifferent_access
    end

    def only_allowed_parent_id(attributes)
      if (parent_id = attributes[:parent_id]) && (parent = Project.find_by(id: parent_id)) &&
        !user.allowed_in_project?(:add_subprojects, parent)
        attributes.except(:parent_id)
      else
        attributes
      end
    end
  end
end
