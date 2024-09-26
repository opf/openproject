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

RSpec.describe EnvData::Saml::ProviderSeeder, :settings_reset do
  let(:seed_data) { Source::SeedData.new({}) }

  subject(:seeder) { described_class.new(seed_data) }

  before do
    reset(:seed_saml_provider,
          description: "Provide a SAML provider and sync its settings through ENV",
          env_alias: "OPENPROJECT_SAML",
          writable: false,
          default: {},
          format: :hash)
  end

  context "when not provided" do
    it "does nothing" do
      expect { seeder.seed! }.not_to change(Saml::Provider, :count)
    end
  end

  context "when providing seed variables",
          with_env: {
            OPENPROJECT_SAML_SAML_NAME: "saml",
            OPENPROJECT_SAML_SAML_DISPLAY__NAME: "Test SAML",
            OPENPROJECT_SAML_SAML_ASSERTION__CONSUMER__SERVICE__URL: "some wrong value",
            OPENPROJECT_SAML_SAML_ASSERTION__CONSUMER__SERVICE__BINDING: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect",
            OPENPROJECT_SAML_SAML_SP__ENTITY__ID: "http://localhost:3000",
            OPENPROJECT_SAML_SAML_IDP__CERT: CertificateHelper.valid_certificate.to_pem,
            OPENPROJECT_SAML_SAML_IDP__SSO__TARGET__URL: "https://saml.example.com/samlp/tPLrXaiBZhLNtzBMN8oNFQAzhFdGlUPK",
            OPENPROJECT_SAML_SAML_IDP__SLO__TARGET__URL: "https://saml.example.com/samlp/tPLrXaiBZhLNtzBMN8oNFQAzhFdGlUPK/logout",
            OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_EMAIL: "['mail', 'urn:oid:2.5.4.42', 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress']",
            OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_LOGIN: "['mail', 'urn:oid:2.5.4.42', 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress']",
            OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_FIRST__NAME: "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname",
            OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_LAST__NAME: "['urn:oid:2.5.4.4', 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']"
          } do
    it "uses those variables" do
      expect { seeder.seed! }.to change(Saml::Provider, :count).by(1)

      provider = Saml::Provider.last
      expect(provider.seeded_from_env?).to be true
      expect(provider.slug).to eq "saml"
      expect(provider.display_name).to eq "Test SAML"

      expect(provider.sp_entity_id).to eq "http://localhost:3000"
      expect(provider.assertion_consumer_service_url).to eq "http://localhost:3000/auth/saml/callback"
      expect(provider.idp_cert).to eq OneLogin::RubySaml::Utils.format_cert(ENV.fetch("OPENPROJECT_SAML_SAML_IDP__CERT"))

      expect(provider.mapping_login).to eq "mail\nurn:oid:2.5.4.42\nhttp://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
      expect(provider.mapping_mail).to eq "mail\nurn:oid:2.5.4.42\nhttp://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
      expect(provider.mapping_firstname).to eq "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname"
      expect(provider.mapping_lastname).to eq "urn:oid:2.5.4.4\nhttp://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname"
    end

    context "when provider already exists with that name" do
      it "updates the provider" do
        provider = Saml::Provider.create!(display_name: "Something", slug: "saml", mapping_mail: "old", creator: User.system)
        expect { seeder.seed! }.not_to change(Saml::Provider, :count)

        provider.reload

        expect(provider.display_name).to eq "Test SAML"
        expect(provider.seeded_from_env?).to be true
        expect(provider.mapping_mail).to eq "mail\nurn:oid:2.5.4.42\nhttp://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
      end
    end
  end

  context "when providing invalid variables",
          with_env: {
            OPENPROJECT_SAML_SAML_NAME: "saml",
            OPENPROJECT_SAML_SAML_DISPLAY__NAME: "Test SAML",
            OPENPROJECT_SAML_SAML_IDP__CERT: "invalid"
          } do
    it "raises an exception" do
      expect { seeder.seed! }.to raise_error(/Idp cert is not a valid PEM-formatted certificate/)

      expect(Saml::Provider.all).to be_empty
    end
  end

  context "when providing multiple variables",
          with_env: {
            OPENPROJECT_SAML_SAML_NAME: "saml",
            OPENPROJECT_SAML_SAML_DISPLAY__NAME: "Test SAML",
            OPENPROJECT_SAML_SAML_ASSERTION__CONSUMER__SERVICE__URL: "some wrong value",
            OPENPROJECT_SAML_SAML_ASSERTION__CONSUMER__SERVICE__BINDING: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect",
            OPENPROJECT_SAML_SAML_SP__ENTITY__ID: "http://localhost:3000",
            OPENPROJECT_SAML_SAML_IDP__CERT: CertificateHelper.non_padded_string(:valid_certificate),
            OPENPROJECT_SAML_SAML_IDP__SSO__TARGET__URL: "https://saml.example.com/samlp/tPLrXaiBZhLNtzBMN8oNFQAzhFdGlUPK",
            OPENPROJECT_SAML_SAML_IDP__SLO__TARGET__URL: "https://saml.example.com/samlp/tPLrXaiBZhLNtzBMN8oNFQAzhFdGlUPK/logout",
            OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_EMAIL: "['mail', 'urn:oid:2.5.4.42', 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress']",
            OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_LOGIN: "['mail', 'urn:oid:2.5.4.42', 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress']",
            OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_FIRST__NAME: "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname",
            OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_LAST__NAME: "['urn:oid:2.5.4.4', 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']",
            OPENPROJECT_SAML_MYSAML_NAME: "mysaml",
            OPENPROJECT_SAML_MYSAML_DISPLAY__NAME: "Another SAML",
            OPENPROJECT_SAML_MYSAML_ASSERTION__CONSUMER__SERVICE__URL: "some wrong value",
            OPENPROJECT_SAML_MYSAML_ASSERTION__CONSUMER__SERVICE__BINDING: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect",
            OPENPROJECT_SAML_MYSAML_SP__ENTITY__ID: "http://localhost:3000",
            OPENPROJECT_SAML_MYSAML_IDP__CERT: CertificateHelper.non_padded_string(:valid_certificate),
            OPENPROJECT_SAML_MYSAML_IDP__SSO__TARGET__URL: "https://saml.example.com/samlp/tPLrXaiBZhLNtzBMN8oNFQAzhFdGlUPK",
            OPENPROJECT_SAML_MYSAML_IDP__SLO__TARGET__URL: "https://saml.example.com/samlp/tPLrXaiBZhLNtzBMN8oNFQAzhFdGlUPK/logout",
            OPENPROJECT_SAML_MYSAML_ATTRIBUTE__STATEMENTS_EMAIL: "['mail', 'urn:oid:2.5.4.42', 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress']",
            OPENPROJECT_SAML_MYSAML_ATTRIBUTE__STATEMENTS_LOGIN: "['mail', 'urn:oid:2.5.4.42', 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress']",
            OPENPROJECT_SAML_MYSAML_ATTRIBUTE__STATEMENTS_FIRST__NAME: "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname",
            OPENPROJECT_SAML_MYSAML_ATTRIBUTE__STATEMENTS_LAST__NAME: "['urn:oid:2.5.4.4', 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname']"
          } do
    it "creates both" do
      expect { seeder.seed! }.to change(Saml::Provider, :count).by(2)

      providers = Saml::Provider.pluck(:slug)
      expect(providers).to contain_exactly("saml", "mysaml")
    end
  end
end
