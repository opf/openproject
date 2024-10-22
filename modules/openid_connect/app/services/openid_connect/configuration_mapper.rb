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
  class ConfigurationMapper
    attr_reader :configuration

    def initialize(configuration)
      @configuration = configuration
    end

    def call! # rubocop:disable Metrics/AbcSize
      options = configuration.deep_stringify_keys

      {
        "slug" => options["name"],
        "display_name" => options["display_name"].presence || "OpenID Connect",
        "oidc_provider" => oidc_provider(options),
        "client_id" => options["identifier"],
        "client_secret" => options["secret"],
        "issuer" => options["issuer"],
        "host" => options["host"],
        "port" => options["port"],
        "scheme" => options["scheme"],
        "claims" => options["claims"],
        "tenant" => options["tenant"],
        "post_logout_redirect_uri" => options["post_logout_redirect_uri"],
        "limit_self_registration" => options["limit_self_registration"],
        "use_graph_api" => options["use_graph_api"],
        "acr_values" => options["acr_values"],
        "authorization_endpoint" => extract_url(options, "authorization_endpoint"),
        "token_endpoint" => extract_url(options, "token_endpoint"),
        "userinfo_endpoint" => extract_url(options, "userinfo_endpoint"),
        "end_session_endpoint" => extract_url(options, "end_session_endpoint"),
        "jwks_uri" => extract_url(options, "jwks_uri"),
        "mapping_login" => options.dig("attribute_map", "login"),
        "mapping_mail" => options.dig("attribute_map", "email"),
        "mapping_firstname" => options.dig("attribute_map", "first_name"),
        "mapping_lastname" => options.dig("attribute_map", "last_name"),
        "mapping_admin" => options.dig("attribute_map", "admin")
      }.compact
    end

    private

    def oidc_provider(options)
      case options["name"]
      when /azure/
        "microsoft_entra"
      when /google/
        "google"
      else
        "custom"
      end
    end

    def extract_url(options, key)
      value = options[key]
      return value if value.blank? || value.start_with?("http")

      unless value.start_with?("/")
        raise ArgumentError.new("Provided #{key} '#{value}' needs to be http(s) URL or path starting with a slash.")
      end

      # Allow returning the value as is for built-in providers
      # with fixed host names
      if oidc_provider(options) != "custom"
        return value
      end

      URI
        .join(base_url(options), value)
        .to_s
    end

    def base_url(options)
      raise ArgumentError.new("Missing host in configuration") unless options["host"]

      URI::Generic.build(
        host: options["host"],
        port: options["port"],
        scheme: options["scheme"] || "https"
      ).to_s
    end
  end
end
