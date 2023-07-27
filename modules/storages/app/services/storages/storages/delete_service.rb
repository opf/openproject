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

# See also: create_service.rb for comments
module Storages::Storages
  class DeleteService < ::BaseServices::Delete
    using Storages::Peripherals::ServiceResultRefinements

    # rubocop:disable Metrics/AbcSize
    def before_perform(params, service_result)
      before_result = super(params, service_result)
      return before_result if before_result.failure? || !model.is_a?(Storages::NextcloudStorage)

      deletion_results =
        model.projects_storages
             .map do |project_storage|
          Storages::Peripherals::StorageRequests
            .new(storage: model)
            .delete_folder_command
            .call(location: project_storage.project_folder_path)
            .match(
              on_success: ->(*) { ServiceResult.success(result: project_storage) },
              on_failure: ->(error) do
                if error.code == :not_found
                  ServiceResult.success(result: project_storage)
                else
                  ServiceResult.failure(errors: error.to_active_model_errors)
                end
              end
            )
        end

      result = ServiceResult.success(result: model)
      result.add_dependent!(*deletion_results) if deletion_results.count > 0
      result
    end
    # rubocop:enable Metrics/AbcSize
  end
end
