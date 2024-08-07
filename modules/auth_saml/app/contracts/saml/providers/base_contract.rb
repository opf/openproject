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
    class BaseContract < ModelContract
      include RequiresAdminGuard

      def self.model
        Saml::Provider
      end

      attribute :display_name
      attribute :options
      attribute :metadata_url
      validates :metadata_url,
                url: { allow_blank: true, allow_nil: true, schemes: %w[http https] },
                if: -> { model.metadata_url_changed? }

      attribute :idp_sso_service_url
      validates :idp_sso_service_url,
                url: { schemes: %w[http https] },
                if: -> { model.idp_sso_service_url_changed? }

      attribute :idp_slo_service_url
      validates :idp_slo_service_url,
                url: { schemes: %w[http https] },
                if: -> { model.idp_slo_service_url_changed? }

      attribute :idp_cert
      validates_presence_of :idp_cert,
                            if: -> { model.idp_cert_changed? }
      validate :idp_cert_is_valid,
               if: -> { model.idp_cert_changed? }

      attribute :authn_requests_signed
      validate :authn_requests_signed_requires_cert

      %i[mapping_mail mapping_login mapping_firstname mapping_lastname].each do |attr|
        attribute attr
        validates_presence_of attr, if: -> { model.public_send(:"#{attr}_changed?") }
      end

      def idp_cert_is_valid
        model.loaded_idp_certificates
      rescue OpenSSL::X509::CertificateError => e
        errors.add :idp_cert, :invalid_certificate, additional_message: e.message
      end

      def valid_certificate
        if model.loaded_certificate.blank?
          errors.add :certificate, :blank
        end
      rescue OpenSSL::OpenSSLError => e
        errors.add :certificate, :invalid_certificate, additional_message: e.message
      end

      def valid_sp_key
        if model.loaded_private_key.blank?
          errors.add :private_key, :blank
        end
      rescue OpenSSL::OpenSSLError => e
        errors.add :private_key, :invalid_private_key, additional_message: e.message
      end

      def authn_requests_signed_requires_cert
        return unless should_test_certificate?
        return if certificate_invalid?

        cert = model.loaded_certificate
        key = model.loaded_private_key

        if cert && key && cert.public_key.public_to_pem != key.public_key.public_to_pem
          errors.add :private_key, :unmatched_private_key
        end
      end

      def certificate_invalid?
        valid_certificate
        valid_sp_key

        errors.any?
      end

      def should_test_certificate?
        return false unless model.authn_requests_signed
        return false unless model.authn_requests_signed_changed? || model.certificate_changed? || model.private_key_changed?

        model.certificate.present? && model.private_key.present?
      end
    end
  end
end
