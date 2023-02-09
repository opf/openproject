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

# This class provides definitions for API routes and endpoints for the file_links namespace. It inherits the
# functionality from the Grape REST API framework. It is mounted in lib/api/v3/work_packages/work_packages_api.rb,
# which puts the file_links namespace behind the provided namespace of the work packages api
# -> /api/v3/work_packages/:id/file_links/...
class API::V3::FileLinks::WorkPackagesFileLinksAPI < API::OpenProjectAPI
  # The `:resources` keyword defines the API namespace -> /api/v3/work_packages/:id/file_links/...
  resources :file_links do
    # Get the list of FileLinks related to a work package, with updated information from Nextcloud.
    get do
      # API supports query filters on storages, for example { storage: { operator: '=', values: [storage_id] }
      query = ParamsToQueryService
                .new(::Storages::Storage,
                     current_user,
                     query_class: ::Queries::Storages::FileLinks::FileLinkQuery)
                .call(params)

      unless query.valid?
        message = I18n.t('api_v3.errors.missing_or_malformed_parameter')
        raise ::API::Errors::InvalidQuery.new(message)
      end

      result = if current_user.allowed_to?(:view_file_links, @work_package.project)
                 # Get a (potentially huge...) list of all FileLinks for the work package.
                 file_links = query.results.where(container_id: @work_package.id,
                                                  container_type: 'WorkPackage',
                                                  storage: @work_package.project.storages)
                 # Synchronize with Nextcloud. StorageAPI has handled OAuth2 for us before.
                 # We ignore the result, because partial errors (storage network issues) are written to each FileLink
                 ::Storages::FileLinkSyncService
                   .new(user: current_user)
                   .call(file_links)
                   .result
               else
                 []
               end
      ::API::V3::FileLinks::FileLinkCollectionRepresenter.new(
        result,
        self_link: api_v3_paths.file_links(@work_package.id),
        current_user:
      )
    end

    post &::API::V3::FileLinks::WorkPackagesFileLinksCreateEndpoint
            .new(
              model: ::Storages::FileLink,
              parse_service: Storages::Peripherals::ParseCreateParamsService,
              render_representer: ::API::V3::FileLinks::FileLinkCollectionRepresenter,
              params_modifier: ->(params) do
                params[:container_id] = work_package.id
                params[:container_type] = work_package.class.name
                params
              end
            )
            .mount
  end
end
