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

module Storages::LastProjectFolders
  class BulkCreateService < ::BaseServices::BaseCallable
    def initialize(user:, project_storages:)
      super()
      @user = user
      @project_storages = project_storages
    end

    def perform
      service_call = validate_permissions
      service_call = validate_contract(service_call) if service_call.success?
      service_call = perform_bulk_create(service_call) if service_call.success?

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

    def validate_contract(service_call)
      set_attributes_results = @project_storages.map do |project_storage|
        set_attributes(project_storage_id: project_storage.id, origin_folder_id: project_storage.project_folder_id,
                       mode: project_storage.project_folder_mode)
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
      bulk_insertion = ::Storages::LastProjectFolder.insert_all(
        service_call.result.map { |model| model.attributes.slice("project_storage_id", "origin_folder_id", "mode") },
        returning: %w[id]
      )
      service_call.result = ::Storages::LastProjectFolder.where(id: bulk_insertion.rows.flatten)

      service_call
    end

    def incoming_projects
      @incoming_projects ||= Project.where(id: @project_storages.pluck(:project_id))
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
      ::Storages::LastProjectFolder.new(params)
    end

    def attributes_service_class
      Storages::LastProjectFolders::SetAttributesService
    end

    def default_contract_class
      Storages::LastProjectFolders::CreateContract
    end
  end
end
