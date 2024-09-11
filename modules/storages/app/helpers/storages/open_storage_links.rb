# frozen_string_literal:true

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

module Storages
  class OpenStorageLinks
    class << self
      include OpenProject::StaticRouting::UrlHelpers

      def static_link(storage)
        api_static_link = ::API::V3::Utilities::PathHelper::ApiV3Path.storage_open(storage.id)

        case storage.provider_type
        when Storage::PROVIDER_TYPE_NEXTCLOUD
          api_static_link
        when Storage::PROVIDER_TYPE_ONE_DRIVE
          raise Errors::ConfigurationError, "No OAuth credential information configured." if storage.oauth_client.nil?

          oauth_clients_ensure_connection_url(
            oauth_client_id: storage.oauth_client.client_id,
            storage_id: storage.id,
            destination_url: api_static_link
          )
        else
          raise ArgumentError, "Cannot generate static open link for storage provider type: #{storage.provider_type}"
        end
      end

      def can_generate_static_link?(storage)
        case storage.provider_type
        when Storage::PROVIDER_TYPE_NEXTCLOUD
          true
        when Storage::PROVIDER_TYPE_ONE_DRIVE
          storage.oauth_client.present?
        else
          false
        end
      end
    end
  end
end
