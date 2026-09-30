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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "services/base_services/behaves_like_update_service"

RSpec.describe ScimClients::UpdateService, type: :model do
  subject { instance.call(params) }

  let(:user) { build_stubbed(:user) }
  let(:instance) { described_class.new(user:, model: scim_client) }
  let(:params) do
    {
      name: "The client name",
      auth_provider_id: auth_provider.id,
      authentication_method: "sso",
      jwt_sub: "123-456"
    }
  end
  let(:auth_provider) { create(:oidc_provider, slug: "provider-slug") }
  let(:scim_client) do
    create(:scim_client, service_account: create(:service_account))
  end

  it_behaves_like "BaseServices update service"

  context "when updating an SSO-based SCIM client with a missing auth provider link" do
    let(:scim_client) do
      create(:scim_client, service_account: create(:service_account), authentication_method: :sso)
    end

    it "updates the service account's name" do
      expect { subject }.to change { scim_client.reload.service_account.name }.to("The client name")
    end

    it "creates the service account's auth provider link", :aggregate_failures do
      expect { subject }.to change(UserAuthProviderLink, :count).by(1)

      link = scim_client.reload.service_account.user_auth_provider_links.first
      expect(link&.auth_provider_id).to eq(auth_provider.id)
      expect(link&.external_id).to eq("123-456")
    end
  end

  context "when updating an SSO-based SCIM client with an existing auth provider link" do
    let(:scim_client) do
      create :scim_client, service_account: create(:service_account, authentication_provider: auth_provider),
                           authentication_method: :sso
    end

    it "updates the service account's name" do
      expect { subject }.to change { scim_client.reload.service_account.name }.to("The client name")
    end

    it "updates the service account's auth provider link", :aggregate_failures do
      subject
      link = scim_client.reload.service_account.user_auth_provider_links.first
      expect(link.auth_provider_id).to eq(auth_provider.id)
      expect(link.external_id).to eq("123-456")
    end
  end

  context "when updating an OAuth2-client-based SCIM client" do
    let(:scim_client) do
      create :scim_client, service_account: create(:service_account),
                           authentication_method: :oauth2_client,
                           oauth_application: create(:oauth_application)
    end
    let(:params) { super().merge(authentication_method: :oauth2_client) }

    it "updates the service account's name" do
      expect { subject }.to change { scim_client.reload.service_account.name }.to("The client name")
    end

    it "does not create an auth provider link" do
      expect { subject }.not_to change(UserAuthProviderLink, :count)
    end
  end

  context "when updating an OAuth2-token-based SCIM client" do
    let(:scim_client) do
      create :scim_client, service_account: create(:service_account),
                           authentication_method: :oauth2_token,
                           oauth_application: create(:oauth_application)
    end
    let(:params) { super().merge(authentication_method: :oauth2_token) }

    it "updates the service account's name" do
      expect { subject }.to change { scim_client.reload.service_account.name }.to("The client name")
    end

    it "does not create an auth provider link" do
      expect { subject }.not_to change(UserAuthProviderLink, :count)
    end
  end
end
