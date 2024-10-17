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
  class BulkCreateService < ::BulkServices::ProjectMappings::BaseCreateService
    attr_reader :storage

    def initialize(user:, projects:, storage:, include_sub_projects: false)
      mapping_context = ::BulkServices::ProjectMappings::MappingContext.new(
        mapping_model_class: ::Storages::ProjectStorage,
        model: storage,
        projects:,
        model_foreign_key_id:,
        include_sub_projects:
      )
      super(user:, mapping_context:)
      @storage = storage
    end

    def after_perform(service_call, params)
      service_call = create_last_project_folders(service_call, params) if service_call.success?
      broadcast_project_storages_created(params) if service_call.success?

      service_call
    end

    private

    def permission = :manage_files_in_project
    def model_foreign_key_id = :storage_id
    def default_contract_class = ::Storages::ProjectStorages::CreateContract

    def validate_contract(service_call, params)
      super_service_call = super

      super_service_call.on_failure do
        super_service_call.errors = super_service_call.errors.first
      end

      super_service_call
    end

    def attributes_from_params(params)
      params.slice(:project_folder_mode, :project_folder_id)
    end

    def perform_bulk_create(service_call)
      bulk_insertion = ::Storages::ProjectStorage.insert_all(
        service_call.result.map { |model| model.attributes.compact },
        unique_by: %i[project_id storage_id],
        returning: %w[id]
      )
      service_call.result = ::Storages::ProjectStorage.where(id: bulk_insertion.rows.flatten)

      service_call
    end

    def create_last_project_folders(service_call, params)
      return service_call if params[:project_folder_mode].to_sym == :inactive

      last_project_folders = ::Storages::LastProjectFolders::BulkCreateService
        .new(user: @user, project_storages: service_call.result)
        .call

      service_call.add_dependent!(last_project_folders)
      service_call
    end

    def broadcast_project_storages_created(params)
      ::Storages::ProjectStorages::NotificationsService.broadcast_raw(
        event: :created,
        project_folder_mode: params[:project_folder_mode],
        project_folder_mode_previously_was: nil,
        storage:
      )
    end
  end
end
