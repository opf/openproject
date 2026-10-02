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

module OpenIDConnect
  module Provider::HashBuilder
    def attribute_map
      OpenIDConnect::Provider::MAPPABLE_ATTRIBUTES
        .index_with { |attr| public_send(:"mapping_#{attr}") }
        .compact_blank
    end

    def to_h # rubocop:disable Metrics/AbcSize
      {
        name: slug,
        oidc_provider:,
        icon:,
        host:,
        scheme:,
        port:,
        display_name:,
        userinfo_endpoint:,
        authorization_endpoint:,
        jwks_uri:,
        issuer:,
        scope:,
        identifier: client_id,
        secret: client_secret,
        token_endpoint:,
        limit_self_registration:,
        end_session_endpoint:,
        attribute_map:,
        post_logout_redirect_uri:,
        claims:,
        acr_values:
      }
       .merge(provider_specific_to_h)
       .compact_blank
    end

    def provider_specific_to_h
      case oidc_provider
      when "google"
        {
          client_auth_method: :not_basic,
          send_nonce: false
        }
      when "microsoft_entra"
        {
          use_graph_api:,
          tenant:
        }
      else
        {}
      end
    end
  end
end
