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

# Reference: https://www.openproject.org/docs/development/concepts/contracted-services/
# The comments here are also valid for the other *_service.rb files
module Storages::ProjectStorages
  class UpdateService < ::BaseServices::Update
    protected

    def after_perform(service_call)
      super

      project_storage = service_call.result
      project_folder_mode = project_storage.project_folder_mode.to_sym
      add_historical_data(service_call) if project_folder_mode != :inactive
      ::Storages::ProjectStorages::NotificationsService.broadcast_project_storage_updated(project_storage:)

      service_call
    end

    private

    def add_historical_data(service_call)
      project_storage = service_call.result
      project_folder = ::Storages::LastProjectFolder
                         .find_by(
                           project_storage_id: project_storage.id,
                           mode: project_storage.project_folder_mode
                         )

      last_project_folder_result =
        if project_folder.nil?
          Helper.create_last_project_folder(
            user:,
            project_storage_id: project_storage.id,
            origin_folder_id: project_storage.project_folder_id,
            mode: project_storage.project_folder_mode
          )
        else
          Helper.update_last_project_folder(
            user:,
            project_folder:,
            origin_folder_id: project_storage.project_folder_id
          )
        end

      service_call.add_dependent!(last_project_folder_result)

      service_call
    end
  end
end
