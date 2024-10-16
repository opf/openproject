#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
module OpenIDConnect
  module Providers
    class BaseContract < ModelContract
      include RequiresAdminGuard

      def self.model
        OpenIDConnect::Provider
      end

      attribute :display_name
      attribute :oidc_provider
      validates :oidc_provider,
                presence: true,
                inclusion: { in: OpenIDConnect::Provider::OIDC_PROVIDERS }
      attribute :slug
      attribute :options
      attribute :limit_self_registration

      attribute :claims
      validate :claims_are_json

      attribute :acr_values

      attribute :metadata_url
      validates :metadata_url,
                url: { allow_blank: true, allow_nil: true, schemes: %w[http https] },
                if: -> { model.metadata_url_changed? }

      attribute :authorization_endpoint
      validates :authorization_endpoint,
                url: { allow_blank: false, allow_nil: false, schemes: %w[http https] },
                if: -> { model.authorization_endpoint_changed? }

      attribute :userinfo_endpoint
      validates :userinfo_endpoint,
                url: { allow_blank: true, allow_nil: true, schemes: %w[http https] },
                if: -> { model.userinfo_endpoint_changed? }

      attribute :token_endpoint
      validates :token_endpoint,
                url: { allow_blank: true, allow_nil: true, schemes: %w[http https] },
                if: -> { model.token_endpoint_changed? }

      attribute :end_session_endpoint
      validates :end_session_endpoint,
                url: { allow_blank: true, allow_nil: true, schemes: %w[http https] },
                if: -> { model.end_session_endpoint_changed? }

      attribute :jwks_uri
      validates :jwks_uri,
                url: { allow_blank: true, allow_nil: true, schemes: %w[http https] },
                if: -> { model.jwks_uri_changed? }

      OpenIDConnect::Provider::MAPPABLE_ATTRIBUTES.each do |attr|
        attribute :"mapping_#{attr}"
      end

      private

      def claims_are_json
        return if claims.blank?

        JSON.parse(claims)
      rescue JSON::ParserError
        errors.add(:claims, :not_json)
      end
    end
  end
end
