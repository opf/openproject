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

require_relative "../support/certificate_helper"

FactoryBot.define do
  factory(:saml_provider, class: "Saml::Provider") do
    sequence(:display_name) { |n| "Saml Provider #{n}" }
    sequence(:slug) { |n| "saml-#{n}" }
    creator factory: :user
    available { true }

    idp_cert { CertificateHelper.valid_certificate.to_pem }
    idp_cert_fingerprint { nil }

    sp_entity_id { "http://#{Setting.host_name}" }

    idp_sso_service_url { "https://example.com/sso" }
    idp_slo_service_url { "https://example.com/slo" }

    mapping_login { Saml::Defaults::MAIL_MAPPING }
    mapping_mail { Saml::Defaults::MAIL_MAPPING }
    mapping_firstname { Saml::Defaults::FIRSTNAME_MAPPING }
    mapping_lastname { Saml::Defaults::LASTNAME_MAPPING }

    trait :with_requested_attributes do
      requested_mail_attribute { Saml::Defaults::MAIL_MAPPING.split("\n").first.strip }
      requested_login_attribute { Saml::Defaults::MAIL_MAPPING.split("\n").first.strip }
      requested_firstname_attribute { Saml::Defaults::FIRSTNAME_MAPPING.split("\n").first.strip }
      requested_lastname_attribute { Saml::Defaults::LASTNAME_MAPPING.split("\n").first.strip }
      requested_login_format { Saml::Defaults::ATTRIBUTE_FORMATS.first }
      requested_mail_format { Saml::Defaults::ATTRIBUTE_FORMATS.first }
      requested_firstname_format { Saml::Defaults::ATTRIBUTE_FORMATS.first }
      requested_lastname_format { Saml::Defaults::ATTRIBUTE_FORMATS.first }
    end

    trait :with_encryption do
      certificate { CertificateHelper.valid_certificate.to_pem }
      private_key { CertificateHelper.private_key.to_pem }
      authn_requests_signed { true }
      want_assertions_signed { true }
      want_assertions_encrypted { true }
      digest_method { Saml::Defaults::DIGEST_METHODS["SHA-256"] }
      signature_method { Saml::Defaults::SIGNATURE_METHODS["RSA SHA-256"] }
    end
  end
end
