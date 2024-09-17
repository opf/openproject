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

class API::V3::FileLinks::FileLinksDownloadAPI < API::OpenProjectAPI
  using Storages::Peripherals::ServiceResultRefinements
  helpers Storages::Peripherals::StorageErrorHelper

  helpers do
    def auth_strategy
      Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken
        .strategy
        .with_user(User.current)
    end
  end

  resources :download do
    get do
      Storages::Peripherals::Registry
        .resolve("#{@file_link.storage.short_provider_type}.queries.download_link")
        .call(storage: @file_link.storage, auth_strategy:, file_link: @file_link)
        .match(
          on_success: ->(url) do
            redirect(url, body: "The requested resource can be downloaded from #{url}")
            status(303)
          end,
          on_failure: ->(error) { raise_error(error) }
        )
    end
  end
end
