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
require "services/base_services/behaves_like_create_service"

RSpec.describe ScimClients::CreateService, type: :model do
  subject { instance.call(params) }

  let(:user) { create(:admin) }
  let(:instance) { described_class.new(user:) }
  let(:params) do
    {
      name: "The client name",
      auth_provider_id: auth_provider.id,
      authentication_method: "sso",
      jwt_sub: "123-456"
    }
  end
  let(:auth_provider) { create(:oidc_provider, slug: "provider-slug") }

  it_behaves_like "BaseServices create service" do
    let(:user) { create(:admin) }
    let(:call_attributes) { params }
  end

  it "creates a service account", :aggregate_failures do
    client = subject.result
    expect(client.service_account).to be_present
    expect(client.service_account&.reload&.name).to eq("The client name")
  end

  it "creates a user auth provider link", :aggregate_failures do
    expect { subject }.to change(UserAuthProviderLink, :count).by(1)

    link = subject.result.service_account.user_auth_provider_links.first
    expect(link.auth_provider).to eq(auth_provider)
    expect(link.external_id).to eq("123-456")
  end

  it "creates no OAuth application" do
    expect { subject }.not_to change(Doorkeeper::Application, :count)
  end

  context "when using oauth2_client as authentication_method" do
    let(:params) do
      {
        name: "The client name",
        auth_provider_id: auth_provider.id,
        authentication_method: "oauth2_client"
      }
    end

    it { is_expected.to be_success }

    it "creates no auth provider link" do
      expect { subject }.not_to change(UserAuthProviderLink, :count)
    end

    it "creates an OAuth application", :aggregate_failures do
      expect { subject }.to change(Doorkeeper::Application, :count).by(1)
      expect(subject.result.oauth_application).to be_present
    end
  end

  context "when using oauth2_token as authentication_method" do
    let(:params) do
      {
        name: "The client name",
        auth_provider_id: auth_provider.id,
        authentication_method: "oauth2_token"
      }
    end

    it { is_expected.to be_success }

    it "creates no auth provider link" do
      expect { subject }.not_to change(UserAuthProviderLink, :count)
    end

    it "creates an OAuth application", :aggregate_failures do
      expect { subject }.to change(Doorkeeper::Application, :count).by(1)
      expect(subject.result.oauth_application).to be_present
    end
  end
end
