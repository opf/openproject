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

RSpec.describe Saml::ConfigurationMapper, type: :model do
  let(:instance) { described_class.new(configuration) }
  let(:result) { instance.call! }

  describe "display_name" do
    subject { result["display_name"] }

    context "when provided" do
      let(:configuration) { { display_name: "My SAML Provider" } }

      it { is_expected.to eq("My SAML Provider") }
    end

    context "when not provided" do
      let(:configuration) { {} }

      it { is_expected.to eq("SAML") }
    end
  end

  describe "slug" do
    subject { result["slug"] }

    context "when provided from name" do
      let(:configuration) { { name: "samlwat" } }

      it { is_expected.to eq("samlwat") }
    end

    context "when not provided" do
      let(:configuration) { {} }

      it { is_expected.to be_nil }
    end
  end

  describe "idp_sso_service_url" do
    subject { result["options"] }

    context "when provided" do
      let(:configuration) { { idp_sso_service_url: "http://example.com" } }

      it { is_expected.to include("idp_sso_service_url" => "http://example.com") }
    end

    context "when provided as legacy" do
      let(:configuration) { { idp_sso_target_url: "http://example.com" } }

      it { is_expected.to include("idp_sso_service_url" => "http://example.com") }
    end
  end

  describe "idp_slo_service_url" do
    subject { result["options"] }

    context "when provided" do
      let(:configuration) { { idp_slo_service_url: "http://example.com" } }

      it { is_expected.to include("idp_slo_service_url" => "http://example.com") }
    end

    context "when provided as legacy" do
      let(:configuration) { { idp_slo_target_url: "http://example.com" } }

      it { is_expected.to include("idp_slo_service_url" => "http://example.com") }
    end
  end

  describe "sp_entity_id" do
    subject { result["options"] }

    context "when provided" do
      let(:configuration) { { sp_entity_id: "http://example.com" } }

      it { is_expected.to include("sp_entity_id" => "http://example.com") }
    end

    context "when provided as legacy" do
      let(:configuration) { { issuer: "http://example.com" } }

      it { is_expected.to include("sp_entity_id" => "http://example.com") }
    end
  end

  describe "idp_cert" do
    let(:idp_cert) { File.read(Rails.root.join("modules/auth_saml/spec/fixtures/idp_cert_plain.txt").to_s) }

    subject { result["options"] }

    context "when provided as single" do
      let(:configuration) do
        { idp_cert: }
      end

      it "formats the certificate" do
        expect(subject["idp_cert"]).to include("BEGIN CERTIFICATE")
        expect(subject["idp_cert"]).to eq(OneLogin::RubySaml::Utils.format_cert(idp_cert))
      end
    end

    context "when provided already formatted" do
      let(:configuration) do
        { idp_cert: OneLogin::RubySaml::Utils.format_cert(idp_cert) }
      end

      it "uses the certificate as is" do
        expect(subject["idp_cert"]).to include("BEGIN CERTIFICATE")
        expect(subject["idp_cert"]).to eq(OneLogin::RubySaml::Utils.format_cert(idp_cert))
      end
    end

    context "when provided as multi" do
      let(:configuration) do
        {
          idp_cert_multi: {
            signing: [idp_cert, idp_cert]
          }
        }
      end

      it "formats the certificate" do
        expect(subject["idp_cert"]).to include("BEGIN CERTIFICATE")
        expect(subject["idp_cert"].scan("BEGIN CERTIFICATE").length).to eq(2)
        formatted = OneLogin::RubySaml::Utils.format_cert(idp_cert)
        expect(subject["idp_cert"]).to eq("#{formatted}\n#{formatted}")
      end
    end
  end

  describe "attribute mapping" do
    let(:configuration) { { attribute_statements: } }

    subject { result["options"] }

    context "when provided" do
      let(:attribute_statements) do
        {
          login: "uid",
          email: %w[email mail],
          first_name: "givenName",
          last_name: "sn",
          uid: "someInternalValue"
        }
      end

      it "extracts the mappings" do
        expect(subject["mapping_login"]).to eq "uid"
        expect(subject["mapping_mail"]).to eq "email\nmail"
        expect(subject["mapping_firstname"]).to eq "givenName"
        expect(subject["mapping_lastname"]).to eq "sn"
        expect(subject["mapping_uid"]).to eq "someInternalValue"
      end
    end

    context "when partially provided" do
      let(:attribute_statements) do
        {
          login: "uid",
          email: "mail"
        }
      end

      it "extracts the mappings" do
        expect(subject["mapping_login"]).to eq "uid"
        expect(subject["mapping_mail"]).to eq "mail"
        expect(subject["mapping_firstname"]).to be_nil
        expect(subject["mapping_lastname"]).to be_nil
        expect(subject["mapping_uid"]).to be_nil
      end
    end

    context "when not provided" do
      let(:attribute_statements) { nil }

      it "does not set any security options" do
        expect(subject["mapping_login"]).to be_nil
        expect(subject["mapping_mail"]).to be_nil
        expect(subject["mapping_firstname"]).to be_nil
        expect(subject["mapping_lastname"]).to be_nil
        expect(subject["mapping_uid"]).to be_nil
      end
    end
  end

  describe "security" do
    let(:configuration) { { security: } }

    subject { result["options"] }

    context "when provided" do
      let(:security) do
        {
          authn_requests_signed: true,
          want_assertions_signed: true,
          want_assertions_encrypted: true,
          digest_method: "http://www.w3.org/2001/04/xmlenc#sha256",
          signature_method: "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256",
          bogus_method: "wat"
        }
      end

      it "extracts the security options" do
        expect(subject).to include(security
                                     .slice(:authn_requests_signed, :want_assertions_signed,
                                            :want_assertions_encrypted, :digest_method, :signature_method)
                                     .stringify_keys)

        expect(subject["authn_requests_signed"]).to be true
        expect(subject["want_assertions_signed"]).to be true
        expect(subject["want_assertions_encrypted"]).to be true
        expect(subject["digest_method"]).to eq("http://www.w3.org/2001/04/xmlenc#sha256")
        expect(subject["signature_method"]).to eq("http://www.w3.org/2001/04/xmldsig-more#rsa-sha256")
        expect(subject).not_to include("bogus_method")
      end
    end

    context "when not provided" do
      let(:security) { nil }

      it "does not set any security options" do
        expect(subject["authn_requests_signed"]).to be_nil
        expect(subject["want_assertions_signed"]).to be_nil
        expect(subject["want_assertions_encrypted"]).to be_nil
        expect(subject["digest_method"]).to be_nil
        expect(subject["signature_method"]).to be_nil
      end
    end
  end
end
