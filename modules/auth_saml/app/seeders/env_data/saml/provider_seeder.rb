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
module EnvData
  module Saml
    class ProviderSeeder < Seeder
      def seed_data!
        Setting.seed_saml_provider.each do |name, options|
          print_status "    ↳ Creating or Updating SAML provider #{name}" do
            provider = ::Saml::Provider.find_by(slug: "saml-env-#{name}")
            options = mapped_options(options)
            params = {
              slug: name,
              display_name: options.delete("display_name") || "SAML",
              available: true,
              options:
            }

            if provider
              print_status "   - Updating existing SAML provider '#{name}' from ENV"
              update(name, provider, params)
            else
              print_status "   - Creating new SAML provider '#{name}' from ENV"
              create(name, params)
            end
          end
        end
      end

      def applicable?
        Setting.seed_saml_provider.present?
      end

      private

      def create(name, params)
        ::Saml::Providers::CreateService
          .new(user: User.system)
          .call(params)
          .on_success { print_status "   - Successfully saved SAML provider #{name}." }
          .on_failure { |call| raise "Failed to create SAML provider: #{call.message}" }
      end

      def update(name, provider, params)
        ::Saml::Providers::UpdateService
          .new(model: provider, user: User.system)
          .call(params)
          .on_success { print_status "   - Successfully updated SAML provider #{name}." }
          .on_failure { |call| raise "Failed to update SAML provider: #{call.message}" }
      end

      def mapped_options(options)
        options["seeded_from_env"] = true
        options["idp_sso_service_url"] ||= options.delete("idp_sso_target_url")
        options["idp_slo_service_url"] ||= options.delete("idp_slo_target_url")
        options["sp_entity_id"] ||= options.delete("issuer")

        build_idp_cert(options)
        extract_security_options(options)
        extract_mapping(options)

        options.compact
      end

      def extract_mapping(options)
        nil unless options["attribute_statements"]

        options["mapping_login"] = extract_mapping_attribute(options, "login")
        options["mapping_mail"] = extract_mapping_attribute(options, "email")
        options["mapping_firstname"] = extract_mapping_attribute(options, "first_name")
        options["mapping_lastname"] = extract_mapping_attribute(options, "last_name")
        options["mapping_uid"] = extract_mapping_attribute(options, "uid")
      end

      def extract_mapping_attribute(options, key)
        value = options["attribute_statements"][key]

        if value.present?
          Array(value).join("\n")
        end
      end

      def build_idp_cert(options)
        if options["idp_cert"]
          options["idp_cert"] = OneLogin::RubySaml::Utils.format_cert(options["idp_cert"])
        elsif options["idp_cert_multi"]
          options["idp_cert"] = options["idp_cert_multi"]["signing"]
            .map { |cert| OneLogin::RubySaml::Utils.format_cert(cert) }
            .join("\n")
        end
      end

      def extract_security_options(options)
        return unless options["security"]

        options.merge! options["security"].slice("authn_requests_signed", "want_assertions_signed",
                                                 "want_assertions_encrypted", "digest_method", "signature_method")
      end
    end
  end
end
