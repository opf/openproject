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
require Rails.root.join("db/migrate/20250804133700_migrate_auth_provider_urls_again.rb")

RSpec.describe MigrateAuthProviderUrlsAgain, type: :model do
  subject(:execute_migration) { ActiveRecord::Migration.suppress_messages { described_class.new.change } }

  let!(:auth_provider) { create(:oidc_provider, slug: "oidc-my-slug") }
  let!(:user) { create(:user) }
  let(:identity_url) { "oidc-my-slug:abc1337" }

  before do
    # side-stepping ActiveRecord here, because we let AR ignore the identity_url column already
    User.connection.execute("UPDATE users SET identity_url = '#{identity_url}' WHERE users.id = #{user.id}")
  end

  it "succeeds" do
    expect { execute_migration }.not_to raise_error
  end

  it "creates a user auth provider link" do
    expect { execute_migration }.to change(UserAuthProviderLink, :count).from(0).to(1)
    expect(UserAuthProviderLink.first.attributes.symbolize_keys).to include(
      external_id: "abc1337", auth_provider_id: auth_provider.id, user_id: user.id
    )
  end

  context "when no auth provider matches the slug" do
    let!(:auth_provider) { create(:oidc_provider, slug: "oidc-other-slug") }

    it "succeeds" do
      expect { execute_migration }.not_to raise_error
    end

    it "creates no user auth provider link" do
      expect { execute_migration }.not_to change(UserAuthProviderLink, :count)
    end
  end

  context "when the user auth provider link already exists" do
    before do
      UserAuthProviderLink.create!(principal: user, auth_provider:, external_id: "abc1337")
    end

    it "succeeds" do
      expect { execute_migration }.not_to raise_error
    end

    it "creates no additional user auth provider link" do
      expect { execute_migration }.not_to change(UserAuthProviderLink, :count)
    end
  end

  context "when there are PluginAuthProviders to be persisted" do
    let(:pending_providers) { { my_slug: "A display name" } }
    let(:identity_url) { "my_slug:1337-7331" }

    before do
      # Hooking into implementation of PluginAuthProvider.create_all_registered to cover that as well in this test case
      allow(PluginAuthProvider).to receive(:registry).and_return(pending_providers)
    end

    it "succeeds" do
      expect { execute_migration }.not_to raise_error
    end

    it "persists them" do
      expect { execute_migration }.to change(PluginAuthProvider, :count).from(0).to(1)
      expect(PluginAuthProvider.first.attributes.symbolize_keys).to include(
        slug: "my_slug", display_name: "A display name", available: false
      )
    end

    it "is able to create user auth provider links for them" do
      expect { execute_migration }.to change(UserAuthProviderLink, :count).from(0).to(1)
      expect(UserAuthProviderLink.first.attributes.symbolize_keys).to include(
        external_id: "1337-7331", auth_provider_id: PluginAuthProvider.first.id, user_id: user.id
      )
    end
  end
end
