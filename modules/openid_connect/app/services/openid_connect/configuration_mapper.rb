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

    def call!
      options = mapped_options(configuration.deep_stringify_keys)

      {
        "slug" => options.delete("name"),
        "display_name" => options.delete("display_name") || "OpenID Connect",
        "oidc_provider" => "custom",
        "client_id" => options["identifier"],
        "client_secret" => options["secret"],
        "issuer" => options["issuer"],
        "authorization_endpoint" => options["authorization_endpoint"],
        "token_endpoint" => options["token_endpoint"],
        "userinfo_endpoint" => options["userinfo_endpoint"],
        "end_session_endpoint" => options["end_session_endpoint"],
        "jwks_uri" => options["jwks_uri"]
      }
    end

    private

    def mapped_options(options)
      extract_mapping(options)

      options.compact
    end

    def extract_mapping(options)
      return unless options["attribute_map"]

      options["mapping_login"] = options["attribute_map"]["login"]
      options["mapping_mail"] = options["attribute_map"]["email"]
      options["mapping_firstname"] = options["attribute_map"]["first_name"]
      options["mapping_lastname"] = options["attribute_map"]["last_name"]
      options["mapping_uid"] = options["attribute_map"]["uid"]
    end
  end
end
