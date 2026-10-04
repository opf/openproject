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

RSpec.describe RemoteIdentity do
  let(:user) { create(:user) }
  let(:integration) { create(:nextcloud_storage) }
  let(:oauth_client) { create(:oauth_client) }
  let(:oidc_provider) { create(:oidc_provider) }

  it "a user can have multiple identities within one integration for different auth source" do
    create(:remote_identity, user:, auth_source: oauth_client, integration:)
    second_identity = build(:remote_identity, user:, auth_source: oidc_provider, integration:)

    expect(second_identity).to be_valid
  end

  it "a user can only have one identity per auth_source and integration" do
    create(:remote_identity, user:, auth_source: oauth_client, integration:)

    invalid = build(:remote_identity, user:, auth_source: oauth_client, integration:)

    expect(invalid).not_to be_valid
    expect(invalid.errors.size).to eq(1)
  end

  it "is destroyed when a user is destroyed" do
    create(:remote_identity, user:)

    expect { user.destroy }.to change(described_class, :count).by(-1)
  end

  it "is destroyed when the related auth source is destroyed" do
    create(:remote_identity, auth_source: oauth_client)
    create(:remote_identity, auth_source: oidc_provider)

    expect { oauth_client.destroy }.to change(described_class, :count).by(-1)
    expect { oidc_provider.destroy }.to change(described_class, :count).by(-1)
  end

  it "is destroyed when the related integration is destroyed" do
    create(:remote_identity, integration:)

    expect { integration.destroy }.to change(described_class, :count).by(-1)
  end
end
