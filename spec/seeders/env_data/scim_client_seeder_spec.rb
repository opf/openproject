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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe EnvData::ScimClientSeeder do
  subject { described_class.new(seed_data).seed! }

  let(:seed_data) { Source::SeedData.new({}) }
  let(:auth_provider) { create(:oidc_provider, slug: "my-provider-slug") }

  before do
    auth_provider
  end

  it "does not seed any clients" do
    expect { subject }.not_to change(ScimClient, :count)
  end

  context "when configuring a client", with_settings: {
    scim_clients: [
      { name: "My SCIM client", auth_provider_slug: "my-provider-slug", jwt_sub: "Princess Donut" }
    ]
  } do
    it "seeds the client with expected data" do
      expect { subject }.to change(ScimClient, :count).from(0).to(1)

      expect(ScimClient.first.name).to eq("My SCIM client")
      expect(ScimClient.first.auth_provider_link.auth_provider_id).to eq(auth_provider.id)
      expect(ScimClient.first.auth_provider_link.external_id).to eq("Princess Donut")
    end

    context "and when a provider with the same name exists" do
      let(:existing_client) { create(:scim_client, name: "My SCIM client") }

      before do
        existing_client
      end

      it "does not seed the client twice" do
        expect { subject }.not_to change(ScimClient, :count)
      end

      it "updates configuration in-place" do
        subject

        expect(ScimClient.first.name).to eq("My SCIM client")
        expect(ScimClient.first.auth_provider_link.auth_provider_id).to eq(auth_provider.id)
        expect(ScimClient.first.auth_provider_link.external_id).to eq("Princess Donut")
      end
    end

    context "and when a provider with a different name exists" do
      let(:existing_client) { create(:scim_client) }

      before do
        existing_client
      end

      it "creates a second client" do
        expect { subject }.to change(ScimClient, :count).from(1).to(2)
      end
    end
  end
end
