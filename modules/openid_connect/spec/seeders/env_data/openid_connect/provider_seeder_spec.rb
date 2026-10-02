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

RSpec.describe EnvData::OpenIDConnect::ProviderSeeder, :settings_reset do
  let(:seed_data) { Source::SeedData.new({}) }

  subject(:seeder) { described_class.new(seed_data) }

  before do
    reset(:seed_oidc_provider,
          description: "Provide a OIDC provider and sync its settings through ENV",
          env_alias: "OPENPROJECT_OPENID__CONNECT",
          writable: false,
          default: {},
          format: :hash)
  end

  context "when not provided" do
    it "does nothing" do
      expect { seeder.seed! }.not_to change(OpenIDConnect::Provider, :count)
    end
  end

  context "when providing seed variables",
          with_env: {
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_DISPLAY__NAME: "Keycloak",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_HOST: "keycloak.local",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_IDENTIFIER: "https://openproject.internal",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_SECRET: "9AWjVC3A4U1HLrZuSP4xiwHfw6zmgECn",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_ISSUER: "https://keycloak.local/realms/master",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_AUTHORIZATION__ENDPOINT: "/realms/master/protocol/openid-connect/auth",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_TOKEN__ENDPOINT: "/realms/master/protocol/openid-connect/token",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_USERINFO__ENDPOINT: "/realms/master/protocol/openid-connect/userinfo",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_END__SESSION__ENDPOINT: "https://keycloak.local/realms/master/protocol/openid-connect/logout",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_JWKS__URI: "https://keycloak.local/realms/master/protocol/openid-connect/certs"
          } do
    it "uses those variables" do
      expect { seeder.seed! }.to change(OpenIDConnect::Provider, :count).by(1)

      provider = OpenIDConnect::Provider.last
      expect(provider.slug).to eq "keycloak"
      expect(provider.display_name).to eq "Keycloak"
      expect(provider.oidc_provider).to eq "custom"
      expect(provider.client_id).to eq "https://openproject.internal"
      expect(provider.client_secret).to eq "9AWjVC3A4U1HLrZuSP4xiwHfw6zmgECn"
      expect(provider.issuer).to eq "https://keycloak.local/realms/master"
      expect(provider.authorization_endpoint).to eq "https://keycloak.local/realms/master/protocol/openid-connect/auth"
      expect(provider.token_endpoint).to eq "https://keycloak.local/realms/master/protocol/openid-connect/token"
      expect(provider.userinfo_endpoint).to eq "https://keycloak.local/realms/master/protocol/openid-connect/userinfo"
      expect(provider.end_session_endpoint).to eq "https://keycloak.local/realms/master/protocol/openid-connect/logout"
      expect(provider.jwks_uri).to eq "https://keycloak.local/realms/master/protocol/openid-connect/certs"
      expect(provider.seeded_from_env?).to be true
    end

    context "when provider already exists with that name" do
      it "updates the provider" do
        provider = OpenIDConnect::Provider.create!(display_name: "Something", slug: "keycloak", creator: User.system)
        expect(provider.seeded_from_env?).to be true

        expect { seeder.seed! }.not_to change(OpenIDConnect::Provider, :count)

        provider.reload

        expect(provider.slug).to eq "keycloak"
        expect(provider.display_name).to eq "Keycloak"
        expect(provider.oidc_provider).to eq "custom"
        expect(provider.client_id).to eq "https://openproject.internal"
        expect(provider.client_secret).to eq "9AWjVC3A4U1HLrZuSP4xiwHfw6zmgECn"
        expect(provider.issuer).to eq "https://keycloak.local/realms/master"
        expect(provider.authorization_endpoint).to eq "https://keycloak.local/realms/master/protocol/openid-connect/auth"
        expect(provider.token_endpoint).to eq "https://keycloak.local/realms/master/protocol/openid-connect/token"
        expect(provider.userinfo_endpoint).to eq "https://keycloak.local/realms/master/protocol/openid-connect/userinfo"
        expect(provider.end_session_endpoint).to eq "https://keycloak.local/realms/master/protocol/openid-connect/logout"
        expect(provider.jwks_uri).to eq "https://keycloak.local/realms/master/protocol/openid-connect/certs"
        expect(provider.seeded_from_env?).to be true
      end
    end
  end

  context "when providing multiple variables",
          with_env: {
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_DISPLAY__NAME: "Keycloak",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_HOST: "keycloak.local",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_IDENTIFIER: "https://openproject.internal",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_SECRET: "9AWjVC3A4U1HLrZuSP4xiwHfw6zmgECn",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_ISSUER: "https://keycloak.local/realms/master",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_AUTHORIZATION__ENDPOINT: "/realms/master/protocol/openid-connect/auth",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_TOKEN__ENDPOINT: "/realms/master/protocol/openid-connect/token",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_USERINFO__ENDPOINT: "/realms/master/protocol/openid-connect/userinfo",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_END__SESSION__ENDPOINT: "https://keycloak.local/realms/master/protocol/openid-connect/logout",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK_JWKS__URI: "https://keycloak.local/realms/master/protocol/openid-connect/certs",

            OPENPROJECT_OPENID__CONNECT_KEYCLOAK123_DISPLAY__NAME: "Keycloak 123",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK123_HOST: "keycloak.local",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK123_IDENTIFIER: "https://openproject.internal",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK123_SECRET: "9AWjVC3A4U1HLrZuSP4xiwHfw6zmgECn",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK123_ISSUER: "https://keycloak.local/realms/master",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK123_AUTHORIZATION__ENDPOINT: "/realms/master/protocol/openid-connect/auth",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK123_TOKEN__ENDPOINT: "/realms/master/protocol/openid-connect/token",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK123_USERINFO__ENDPOINT: "/realms/master/protocol/openid-connect/userinfo",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK123_END__SESSION__ENDPOINT: "https://keycloak.local/realms/master/protocol/openid-connect/logout",
            OPENPROJECT_OPENID__CONNECT_KEYCLOAK123_JWKS__URI: "https://keycloak.local/realms/master/protocol/openid-connect/certs"
          } do
    it "creates both" do
      expect { seeder.seed! }.to change(OpenIDConnect::Provider, :count).by(2)

      providers = OpenIDConnect::Provider.pluck(:slug)
      expect(providers).to contain_exactly("keycloak", "keycloak123")
    end
  end
end
