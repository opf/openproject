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

module Saml
  module Providers
    class SetAttributesService < BaseServices::SetAttributes
      private

      def set_attributes(params)
        update_mapping(params)
        update_options(params.delete(:options)) if params.key?(:options)

        super

        update_available_state
      end

      def update_available_state
        model.change_by_system do
          model.available = model.configured? && model.mapping_configured?
        end
      end

      def update_options(options)
        update_idp_cert(options.delete(:idp_cert)) if options.key?(:idp_cert)

        options
          .select { |key, _| Saml::Provider.stored_attributes[:options].include?(key.to_s) }
          .each do |key, value|
          model.public_send(:"#{key}=", value)
        end
      end

      def set_default_attributes(*)
        model.change_by_system do
          set_default_creator
          set_default_mapping
          set_default_requested_attributes
          set_issuer
          set_name_identifier_format
          set_default_digest
        end
      end

      def set_default_digest
        model.signature_method ||= Saml::Defaults::SIGNATURE_METHODS["RSA SHA-1"]
        model.digest_method ||= Saml::Defaults::DIGEST_METHODS["SHA-1"]
      end

      def set_name_identifier_format
        model.name_identifier_format ||= Saml::Defaults::NAME_IDENTIFIER_FORMAT
      end

      def set_default_creator
        model.creator = user
      end

      def update_idp_cert(cert)
        model.idp_cert =
          if cert.include?("BEGIN CERTIFICATE")
            cert
          else
            OneLogin::RubySaml::Utils.format_cert(cert)
          end
      end

      ##
      # Clean up provided mapping, reducing whitespace
      def update_mapping(params)
        %i[mapping_mail mapping_login mapping_firstname mapping_lastname].each do |attr|
          next unless params.key?(attr)

          mapping = params.delete(attr)
          mapping.gsub!("\r\n", "\n")
          mapping.gsub!(/^\s*(.+?)\s*$/, '\1')

          model.public_send(:"#{attr}=", mapping)
        end
      end

      def set_default_mapping
        model.mapping_login ||= Saml::Defaults::MAIL_MAPPING
        model.mapping_mail ||= Saml::Defaults::MAIL_MAPPING
        model.mapping_firstname ||= Saml::Defaults::FIRSTNAME_MAPPING
        model.mapping_lastname ||= Saml::Defaults::LASTNAME_MAPPING
      end

      def set_default_requested_attributes
        model.requested_login_attribute ||= Saml::Defaults::MAIL_MAPPING.split("\n").first
        model.requested_mail_attribute ||= Saml::Defaults::MAIL_MAPPING.split("\n").first
        model.requested_firstname_attribute ||= Saml::Defaults::FIRSTNAME_MAPPING.split("\n").first
        model.requested_lastname_attribute ||= Saml::Defaults::LASTNAME_MAPPING.split("\n").first

        model.requested_login_format ||= Saml::Defaults::ATTRIBUTE_FORMATS.first
        model.requested_mail_format ||= Saml::Defaults::ATTRIBUTE_FORMATS.first
        model.requested_firstname_format ||= Saml::Defaults::ATTRIBUTE_FORMATS.first
        model.requested_lastname_format ||= Saml::Defaults::ATTRIBUTE_FORMATS.first
      end

      def set_issuer
        model.sp_entity_id ||= OpenProject::StaticRouting::StaticUrlHelpers.new.root_url
      end
    end
  end
end
