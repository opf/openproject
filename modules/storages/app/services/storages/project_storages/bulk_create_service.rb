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

module Storages::ProjectStorages
  class BulkCreateService < ::BaseServices::BaseCallable
    def initialize(user:, projects:, storage:, project_folder_mode:, include_sub_projects: false)
      super()
      @user = user
      @projects = projects
      @storage = storage
      @project_folder_mode = project_folder_mode
      @include_sub_projects = include_sub_projects
    end

    def perform
      service_call = validate_permissions
      service_call = validate_contract(service_call, incoming_activations_ids) if service_call.success?
      service_call = perform_bulk_create(service_call) if service_call.success?
      service_call = create_last_project_folders(service_call) if service_call.success?
      broadcast_project_storages_created if service_call.success?

      service_call
    end

    private

    def validate_permissions
      return ServiceResult.failure(errors: I18n.t(:label_not_found)) if incoming_projects.empty?

      if @user.allowed_in_project?(:manage_files_in_project, incoming_projects)
        ServiceResult.success
      else
        ServiceResult.failure(errors: I18n.t("activerecord.errors.messages.error_unauthorized"))
      end
    end

    def validate_contract(service_call, project_ids)
      set_attributes_results = project_ids.map do |id|
        set_attributes(project_id: id, storage_id: @storage.id, project_folder_mode: @project_folder_mode)
      end

      if (failures = set_attributes_results.select(&:failure?)).any?
        service_call.success = false
        service_call.errors = failures.map(&:errors)
      else
        service_call.result = set_attributes_results.map(&:result)
      end

      service_call
    end

    def perform_bulk_create(service_call)
      bulk_insertion = ::Storages::ProjectStorage.insert_all(
        service_call.result.map do |model|
          model.attributes.slice("project_id", "storage_id", "project_folder_mode", "creator_id")
        end,
        unique_by: %i[project_id storage_id],
        returning: %w[id]
      )
      service_call.result = ::Storages::ProjectStorage.where(id: bulk_insertion.rows.flatten)

      service_call
    end

    def create_last_project_folders(service_call)
      return service_call if @project_folder_mode.to_sym == :inactive

      last_project_folders = ::Storages::LastProjectFolders::BulkCreateService
        .new(user: @user, project_storages: service_call.result)
        .call

      service_call.add_dependent!(last_project_folders)
      service_call
    end

    def broadcast_project_storages_created
      OpenProject::Notifications.send(
        OpenProject::Events::PROJECT_STORAGE_CREATED,
        project_folder_mode: @project_folder_mode,
        storage: @storage
      )
    end

    def incoming_activations_ids
      project_ids = incoming_projects.pluck(:id)
      project_ids - existing_project_storages(project_ids)
    end

    def incoming_projects
      @projects.each_with_object(Set.new) do |project, projects_set|
        next unless project.active?

        projects_set << project
        projects_set.merge(project.active_subprojects.to_a) if @include_sub_projects
      end.to_a
    end

    def existing_project_storages(project_ids)
      ::Storages::ProjectStorage
        .where(storage_id: @storage.id, project_id: project_ids)
        .pluck(:project_id)
    end

    def set_attributes(params)
      attributes_service_class
        .new(user: @user,
             model: instance(params),
             contract_class: default_contract_class,
             contract_options: {})
        .call(params)
    end

    def instance(params)
      ::Storages::ProjectStorage.new(params)
    end

    def attributes_service_class
      ::Storages::ProjectStorages::SetAttributesService
    end

    def default_contract_class
      ::Storages::ProjectStorages::CreateContract
    end
  end
end
