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

# This class provides definitions for API routes and endpoints for the storages namespace. It inherits the
# functionality from the Grape REST API framework. It is mounted in lib/api/v3/root.rb.
# `modules/storages/lib/` is a defined root directory for grape, providing a root level look up for the namespaces.
# Hence, the modules of the class have to be represented in the directory structure.

# OpenProjectAPI is a simple subclass of Grape::API that handles patches.
class API::V3::Storages::StoragesAPI < API::OpenProjectAPI
  # helpers is defined by the grape framework. They make methods from the
  # module available from within the endpoint context.
  helpers Storages::Peripherals::Scopes

  # The `:resources` keyword defines the API namespace -> /api/v3/storages/...
  resources :storages do
    # post &::API::V3::Storages::CreateEndpoint.new(model: ::Storages::Storage).mount
    post &API::V3::Utilities::Endpoints::Create.new(model: Storages::Storage).mount

    # `route_param` extends the route by a route parameter of the endpoint.
    # The input parameter value is parsed into the `:storage_id` symbol.
    route_param :storage_id, type: Integer, desc: 'Storage id' do
      # Execute the do...end lines after parameter validation but before the actual
      # call to the API method.
      # Please see: The after_validation call-back in Grape:
      # https://github.com/ruby-grape/grape#before-after-and-finally
      after_validation do
        @storage = visible_storages.find(params[:storage_id])
      end

      # A helper is used to define the behaviour at GET /api/v3/storages/:storage_id
      # The endpoint helper standardizes a lot of the parsing, validation and rendering logic.
      # the `mount` method from the endpoint returns a proc. This proc is
      # passed as a block to the `get` helper thanks to the `&` operator.
      # The block will get called everytime a GET request is sent to this
      # route.
      get &API::V3::Utilities::Endpoints::Show.new(model: Storages::Storage).mount

      patch &API::V3::Utilities::Endpoints::Update.new(model: Storages::Storage).mount

      delete &API::V3::Utilities::Endpoints::Delete.new(model: Storages::Storage).mount

      mount API::V3::StorageFiles::StorageFilesAPI
      mount API::V3::OAuthClient::OAuthClientCredentialsAPI
    end
  end
end
