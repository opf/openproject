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

class API::V3::Storages::StoragesAPI < API::OpenProjectAPI
  helpers Storages::Peripherals::Scopes

  resources :storages do
    post &API::V3::Utilities::Endpoints::Create.new(model: Storages::Storage).mount

    get &API::V3::Utilities::Endpoints::Index.new(model: Storages::Storage, scope: -> { visible_storages }).mount

    route_param :storage_id, type: Integer, desc: "Storage id" do
      after_validation do
        @storage = visible_storages.find(params[:storage_id])
      end

      get &API::V3::Utilities::Endpoints::Show.new(model: Storages::Storage).mount

      patch &API::V3::Utilities::Endpoints::Update.new(model: Storages::Storage).mount

      delete &API::V3::Utilities::Endpoints::Delete.new(model: Storages::Storage).mount

      mount API::V3::StorageFiles::StorageFilesAPI
      mount API::V3::OAuthClient::OAuthClientCredentialsAPI
      mount API::V3::Storages::StorageOpenAPI
    end
  end
end
