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

require Rails.root.join("modules/openid_connect/db/migrate/20240829140616_migrate_oidc_settings_to_providers.rb")
RSpec.describe MigrateOidcSettingsToProviders, type: :model do
  # Define a custom class,
  # Class.new doesn't work here as STI uses .constantize
  # rubocop:disable Lint/ConstantDefinitionInBlock,RSpec/LeakyConstantDeclaration
  class TestOpenIDConnectProvider < OpenIDConnect::Provider
    self.table_name = "test_openid_connect_provider"
  end
  # rubocop:enable Lint/ConstantDefinitionInBlock,RSpec/LeakyConstantDeclaration

  subject { described_class.new.up }

  let(:test_provider_table_name) { "test_openid_connect_provider" }

  # Mock the create service so we can test with the test provider
  before do
    allow_any_instance_of(OpenIDConnect::Providers::CreateService) # rubocop:disable RSpec/AnyInstance
      .to receive(:instance_class).and_return(TestOpenIDConnectProvider)
  end

  around do |example|
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table(test_provider_table_name) do |t|
        t.string :type, null: false
        t.string :display_name, null: false, index: { unique: true }
        t.string :slug, null: false, index: { unique: true }
        t.boolean :available, null: false, default: true
        t.boolean :limit_self_registration, null: false, default: false
        t.jsonb :options, default: {}, null: false
        t.references :creator, null: false, index: true, foreign_key: { to_table: :users }

        t.timestamps
      end

      example.run
    ensure
      ActiveRecord::Migration.drop_table(test_provider_table_name)
    end
  end

  context "when no provider present",
          with_settings: { plugin_openproject_openid_connect: nil } do
    it "does nothing" do
      allow(OpenIDConnect::SyncService).to receive(:new)

      subject

      expect(OpenIDConnect::SyncService).not_to have_received(:new)
    end
  end

  context "when a provider present, but invalid",
          with_settings: {
            plugin_openproject_openid_connect: {
              providers: {
                keycloak: {
                  display_name: "Keycloak",
                  token_endpoint: "wat?"
                }
              }
            }
          } do
    it "raises an error" do
      expect { subject }.to raise_error do |error|
        expect(error.message).to include "Failed to create or update OpenID provider keycloak from previous settings format"
        expect(error.message).to include "Provided token_endpoint 'wat?' needs to be http(s) URL or path starting with a slash."
      end
    end
  end

  context "when a provider correctly provided",
          with_settings: {
            plugin_openproject_openid_connect: {
              providers: {
                keycloak: {
                  display_name: "Keycloak",
                  host: "localhost",
                  port: "8080",
                  scheme: "http",
                  identifier: "http://localhost:3000",
                  secret: "IVl6GxxujAQ3mt6thAXKxyYYvmyRr8jw",
                  issuer: "http://localhost:8080/realms/test",
                  authorization_endpoint: "/realms/test/protocol/openid-connect/auth",
                  token_endpoint: "/realms/test/protocol/openid-connect/token",
                  userinfo_endpoint: "/realms/test/protocol/openid-connect/userinfo",
                  end_session_endpoint: "http://localhost:8080/realms/test/protocol/openid-connect/logout",
                  post_logout_redirect_uri: "http://localhost:3000",
                  limit_self_registration: true,
                  attribute_map: { login: "foo", admin: "isAdmin" }
                }
              }
            }
          } do
    it "migrates correctly" do # rubocop:disable RSpec/MultipleExpectations
      expect { subject }.to change(TestOpenIDConnectProvider, :count).by(1)

      provider = TestOpenIDConnectProvider.last
      expect(provider.display_name).to eq "Keycloak"
      expect(provider.host).to eq "localhost"
      expect(provider.port).to eq "8080"
      expect(provider.scheme).to eq "http"
      expect(provider.client_id).to eq "http://localhost:3000"
      expect(provider.client_secret).to eq "IVl6GxxujAQ3mt6thAXKxyYYvmyRr8jw"
      expect(provider.issuer).to eq "http://localhost:8080/realms/test"
      expect(provider.authorization_endpoint).to eq "http://localhost:8080/realms/test/protocol/openid-connect/auth"
      expect(provider.token_endpoint).to eq "http://localhost:8080/realms/test/protocol/openid-connect/token"
      expect(provider.userinfo_endpoint).to eq "http://localhost:8080/realms/test/protocol/openid-connect/userinfo"
      expect(provider.end_session_endpoint).to eq "http://localhost:8080/realms/test/protocol/openid-connect/logout"
      expect(provider.post_logout_redirect_uri).to eq "http://localhost:3000"
      expect(provider.limit_self_registration).to be true
      expect(provider.mapping_login).to eq "foo"
      expect(provider.mapping_admin).to eq "isAdmin"
      expect(provider.mapping_email).to be_blank
    end
  end
end
