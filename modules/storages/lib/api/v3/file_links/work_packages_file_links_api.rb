#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
module API
  module V3
    module FileLinks
      class WorkPackagesFileLinksAPI < ::API::OpenProjectAPI
        # helpers is defined by the grape framework. They make methods from the
        # module available from within the endpoint context.
        helpers API::V3::Utilities::StoragesHelpers

        before do
          reply_with_not_found_if_module_inactive
        end

        # The `:resources` keyword defines the API namespace -> /api/v3/work_packages/:id/file_links/...
        resources :file_links do
          # A helper is used to define the behaviour at GET /api/v3/work_packages/:id/file_links
          get &::API::V3::Utilities::Endpoints::Index
                 .new(model: ::Storages::FileLink,
                      scope: -> { visible_file_links_scope.where(container_id: @work_package.id) },
                      self_path: -> { api_v3_paths.file_links(params[:id]) })
                 .mount

          # A helper is used to define the behaviour at POST /api/v3/work_packages/:id/file_links.
          # Additional classes are provided, that overwrite standard behaviour for parsing request parameters or
          # rendering the response.
          post &CreateEndpoint
                  .new(
                    model: ::Storages::FileLink,
                    parse_service: ParseCreateParamsService,
                    render_representer: FileLinkCollectionRepresenter
                  )
                  .mount
        end
      end
    end
  end
end
