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

require "spec_helper"
require_module_spec_helper

RSpec.describe Saml::Providers::SetAttributesService, type: :model do
  let(:current_user) { build_stubbed(:admin) }

  let(:instance) do
    described_class.new(user: current_user,
                        model: model_instance,
                        contract_class:,
                        contract_options: {})
  end

  let(:params) do
    { options: }
  end
  let(:call) { instance.call(params) }

  subject { call.result }

  describe "new instance" do
    let(:model_instance) { Saml::Provider.new(display_name: "foo") }
    let(:contract_class) { Saml::Providers::CreateContract }

    describe "default attributes" do
      let(:options) { {} }

      it "sets all default attributes", :aggregate_failures do
        expect(subject.display_name).to eq "foo"
        expect(subject.slug).to eq "saml-foo"
        expect(subject.creator).to eq(current_user)
        expect(subject.sp_entity_id).to eq(OpenProject::StaticRouting::StaticUrlHelpers.new.root_url)
        expect(subject.name_identifier_format).to eq("urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress")
        expect(subject.signature_method).to eq(Saml::Defaults::SIGNATURE_METHODS["RSA SHA-1"])
        expect(subject.digest_method).to eq(Saml::Defaults::DIGEST_METHODS["SHA-1"])

        expect(subject.mapping_mail).to eq Saml::Defaults::MAIL_MAPPING
        expect(subject.mapping_firstname).to eq Saml::Defaults::FIRSTNAME_MAPPING
        expect(subject.mapping_lastname).to eq Saml::Defaults::LASTNAME_MAPPING
        expect(subject.mapping_uid).to be_blank
        expect(subject.mapping_login).to eq Saml::Defaults::MAIL_MAPPING

        expect(subject.requested_login_attribute).to eq "mail"
        expect(subject.requested_mail_attribute).to eq "mail"
        expect(subject.requested_firstname_attribute).to eq "givenName"
        expect(subject.requested_lastname_attribute).to eq "sn"

        expect(subject.requested_login_format).to eq "urn:oasis:names:tc:SAML:2.0:attrname-format:basic"
        expect(subject.requested_mail_format).to eq "urn:oasis:names:tc:SAML:2.0:attrname-format:basic"
        expect(subject.requested_firstname_format).to eq "urn:oasis:names:tc:SAML:2.0:attrname-format:basic"
        expect(subject.requested_lastname_format).to eq "urn:oasis:names:tc:SAML:2.0:attrname-format:basic"
      end
    end

    describe "SLO URL" do
      let(:options) do
        {
          idp_slo_service_url:
        }
      end

      context "when nil" do
        let(:idp_slo_service_url) { nil }

        it "is valid" do
          expect(call).to be_success
          expect(call.errors).to be_empty

          expect(subject.idp_slo_service_url).to be_nil
        end
      end

      context "when blank" do
        let(:idp_slo_service_url) { "" }

        it "is valid" do
          expect(call).to be_success
          expect(call.errors).to be_empty

          expect(subject.idp_slo_service_url).to eq ""
        end
      end

      context "when not a URL" do
        let(:idp_slo_service_url) { "foo!" }

        it "is valid" do
          expect(call).not_to be_success
          expect(call.errors.details[:idp_slo_service_url])
            .to contain_exactly({ error: :url, value: idp_slo_service_url })
        end
      end

      context "when invalid scheme" do
        let(:idp_slo_service_url) { "urn:some:info" }

        it "is valid" do
          expect(call).not_to be_success
          expect(call.errors.details[:idp_slo_service_url])
            .to contain_exactly({ error: :url, value: idp_slo_service_url })
        end
      end

      context "when valid" do
        let(:idp_slo_service_url) { "https://foobar.example.com/slo" }

        it "is valid" do
          expect(call).to be_success
          expect(call.errors).to be_empty

          expect(subject.idp_slo_service_url).to eq idp_slo_service_url
        end
      end
    end

    describe "IDP certificate" do
      let(:options) do
        {
          idp_cert: certificate
        }
      end

      context "with a valid certificate" do
        let(:certificate) { CertificateHelper.valid_certificate.to_pem }

        it "assigns the certificate" do
          expect(call).to be_success
          expect(call.errors).to be_empty

          expect(subject.idp_cert).to eq CertificateHelper.valid_certificate.to_pem
        end
      end

      context "with a valid certificate, not in pem format" do
        let(:certificate) { CertificateHelper.valid_certificate.to_pem.lines[1...-1].join }

        it "assigns the certificate" do
          expect(call).to be_success
          expect(call.errors).to be_empty

          expect(subject.idp_cert).to eq CertificateHelper.valid_certificate.to_pem.strip
        end
      end

      context "with two certificates, one expired" do
        let(:certificate) do
          "#{CertificateHelper.valid_certificate.to_pem}\n#{CertificateHelper.expired_certificate.to_pem}"
        end

        it "assigns the certificate" do
          expect(call).to be_success
          expect(call.errors).to be_empty

          expect(subject.idp_cert).to eq certificate
        end
      end

      context "with an invalid certificate" do
        let(:certificate) { CertificateHelper.expired_certificate.to_pem }

        it "assigns the certificate" do
          expect(call).not_to be_success
          expect(call.errors.details[:idp_cert]).to contain_exactly({ error: :certificate_expired })
        end
      end
    end

    describe "certificate and private key" do
      let(:options) do
        {
          certificate: given_certificate,
          private_key: given_private_key
        }
      end

      context "with a valid certificate pair" do
        let(:given_certificate) { CertificateHelper.valid_certificate.to_pem }
        let(:given_private_key) { CertificateHelper.private_key.private_to_pem }

        it "assigns the certificate" do
          expect(call).to be_success
          expect(call.errors).to be_empty

          expect(subject.certificate).to eq given_certificate.strip
          expect(subject.private_key).to eq given_private_key.strip
        end
      end

      context "with an invalid certificate" do
        let(:given_certificate) { CertificateHelper.expired_certificate.to_pem }
        let(:given_private_key) { nil }

        it "results in an error" do
          expect(call).not_to be_success
          expect(call.errors.details[:certificate]).to contain_exactly({ error: :certificate_expired })
          expect(call.errors.details[:private_key]).to contain_exactly({ error: :blank })
        end
      end

      context "with a mismatched certificate" do
        let(:given_certificate) { CertificateHelper.mismatched_certificate.to_pem }
        let(:given_private_key) { CertificateHelper.private_key.private_to_pem }

        it "results in an error" do
          expect(call).not_to be_success
          expect(call.errors.details[:private_key]).to contain_exactly({ error: :unmatched_private_key })
        end
      end
    end

    describe "mapping" do
      let(:options) do
        {
          mapping_mail: "mail\n  whitespace  \nfoo",
          mapping_firstname: "name\nsn",
          mapping_lastname: "hello  ",
          mapping_uid: "something"
        }
      end

      it "assigns the given and default values", :aggregate_failures do
        expect(call).to be_success
        expect(call.errors).to be_empty

        expect(subject.mapping_mail).to eq "mail\nwhitespace\nfoo"
        expect(subject.mapping_firstname).to eq "name\nsn"
        expect(subject.mapping_lastname).to eq "hello"
        expect(subject.mapping_uid).to eq "something"

        expect(subject.mapping_login).to eq Saml::Defaults::MAIL_MAPPING
      end
    end

    describe "want_assertions_signed" do
      context "when provided" do
        let(:options) { { want_assertions_signed: true } }

        it "assigns the value" do
          expect(call).to be_success
          expect(call.errors).to be_empty

          expect(subject.want_assertions_signed).to be true
        end
      end

      context "when not provided" do
        let(:options) { {} }

        it "assigns the default value" do
          expect(call).to be_success
          expect(call.errors).to be_empty

          expect(subject.want_assertions_signed).to be false
        end
      end
    end

    describe "want_assertions_encrypted" do
      context "when provided" do
        let(:options) { { want_assertions_encrypted: true } }

        it "assigns the value" do
          expect(call).to be_success
          expect(call.errors).to be_empty

          expect(subject.want_assertions_encrypted).to be true
        end
      end

      context "when not provided" do
        let(:options) { {} }

        it "assigns the default value" do
          expect(call).to be_success
          expect(call.errors).to be_empty

          expect(subject.want_assertions_encrypted).to be false
        end
      end
    end

    describe "authn_requests_signed" do
      context "when provided" do
        let(:options) { { authn_requests_signed: true } }

        it "assigns the value" do
          expect(call).to be_success
          expect(call.errors).to be_empty

          expect(subject.authn_requests_signed).to be true
        end
      end

      context "when not provided" do
        let(:options) { {} }

        it "assigns the default value" do
          expect(call).to be_success
          expect(call.errors).to be_empty

          expect(subject.authn_requests_signed).to be false
        end
      end
    end
  end
end
