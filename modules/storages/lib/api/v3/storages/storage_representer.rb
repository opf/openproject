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

# Reference: Representable https://trailblazer.to/2.1/docs/representable.html
#   "Representable maps Ruby objects to documents and back"
# Reference: Roar is a thin layer on top of Representable https://github.com/trailblazer/roar
# Reference: Roar-Rails integration: https://github.com/apotonick/roar-rails
module API::V3::Storages
  URN_CONNECTION_CONNECTED = "#{::API::V3::URN_PREFIX}storages:authorization:Connected".freeze
  URN_CONNECTION_AUTH_FAILED = "#{::API::V3::URN_PREFIX}storages:authorization:FailedAuthorization".freeze
  URN_CONNECTION_ERROR = "#{::API::V3::URN_PREFIX}storages:authorization:Error".freeze

  class StorageRepresenter < ::API::Decorators::Single
    # LinkedResource module defines helper methods to describe attributes
    include API::Decorators::LinkedResource
    include API::Decorators::DateProperty
    include Storages::Peripherals::StorageUrlHelper

    def initialize(model, current_user:, embed_links: nil)
      @connection_manager =
        ::OAuthClients::ConnectionManager.new(user: current_user, oauth_client: model.oauth_client)

      super
    end

    property :id

    property :name

    date_time_property :created_at

    date_time_property :updated_at

    self_link

    link :type do
      {
        href: "#{::API::V3::URN_PREFIX}storages:Nextcloud",
        title: 'Nextcloud'
      }
    end

    link :origin do
      { href: represented.host }
    end

    link :open do
      { href: storage_url_open(represented) }
    end

    link :authorizationState do
      state = @connection_manager.authorization_state
      urn = case state
            when :connected
              URN_CONNECTION_CONNECTED
            when :failed_authorization
              URN_CONNECTION_AUTH_FAILED
            else
              URN_CONNECTION_ERROR
            end
      title = I18n.t(:"oauth_client.urn_connection_status.#{state}")

      { href: urn, title: }
    end

    link :authorize do
      next unless @connection_manager.authorization_state == :failed_authorization

      { href: @connection_manager.get_authorization_uri, title: 'Authorize' }
    end

    def _type
      'Storage'
    end
  end
end
