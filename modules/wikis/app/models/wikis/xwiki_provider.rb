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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Wikis
  class XWikiProvider < Provider
    AUTHENTICATION_METHODS = [
      AUTHENTICATION_METHOD_TWO_WAY_OAUTH2 = "two_way_oauth2"
      # AUTHENTICATION_METHOD_OAUTH2_SSO = "oauth2_sso" # not yet implemented
    ].freeze

    has_one :oauth_client, as: :integration, dependent: :destroy
    has_one :oauth_application, class_name: "::Doorkeeper::Application", as: :integration, dependent: :destroy

    store_attribute :options, :url, :string
    store_attribute :options, :authentication_method, :string, default: "two_way_oauth2"
    store_attribute :options, :wiki_audience, :string
    store_attribute :options, :token_exchange_scope, :string

    class << self
      def registry_prefix = "xwiki"
      def generate_client_id = "openproject-#{SecureRandom.hex(8)}"
      def generate_client_secret = SecureRandom.alphanumeric(32)
    end

    def configured?
      url.present? &&
        oauth_client.present? &&
        oauth_application.present?
    end

    def non_confidential_configuration
      super.merge(
        url:,
        oauth_client_id: oauth_client&.client_id,
        oauth_application_client_id: oauth_application&.uid
      )
    end

    def user_connected?(user)
      return true if oauth_client.blank?

      OAuthClientToken.for_user_and_client(user, oauth_client).exists?
    end

    def extract_origin_user_id(token)
      auth_strategy_for(token.user).bind do |auth_strategy|
        resolve("queries.user").call(auth_strategy:)
      end
    end

    def authenticate_via_two_way_oauth2?
      authentication_method == AUTHENTICATION_METHOD_TWO_WAY_OAUTH2
    end

    def oauth_configuration
      Wikis::Adapters::Providers::XWiki::OAuthConfiguration.new(self)
    end
  end
end
