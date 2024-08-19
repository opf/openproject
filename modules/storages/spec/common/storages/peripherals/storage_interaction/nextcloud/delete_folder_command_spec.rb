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

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::DeleteFolderCommand, :vcr, :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:storage) do
    create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
  end
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
  end

  it "is registered as commands.nextcloud.delete_folder" do
    expect(Storages::Peripherals::Registry.resolve("nextcloud.commands.delete_folder")).to eq(described_class)
  end

  describe "#call" do
    it "responds with correct parameters" do
      expect(described_class).to respond_to(:call)

      method = described_class.method(:call)
      expect(method.parameters).to contain_exactly(%i[keyreq storage],
                                                   %i[keyreq auth_strategy],
                                                   %i[keyreq location])
    end

    it "deletes a folder", vcr: "nextcloud/delete_folder" do
      parent_location = Storages::Peripherals::ParentFolder.new("/")

      Storages::Peripherals::Registry
        .resolve("nextcloud.commands.create_folder")
        .call(storage:, auth_strategy:, folder_name: "To Be Deleted Soon", parent_location:)

      result = described_class.call(storage:, auth_strategy:, location: "/To Be Deleted Soon")

      expect(result).to be_success
    end

    context "if folder does not exist" do
      it "returns a failure", vcr: "nextcloud/delete_folder_not_found" do
        result = described_class.call(storage:, auth_strategy:, location: "/IDoNotExist")

        expect(result).to be_failure
        expect(result.error_source)
          .to be(Storages::Peripherals::StorageInteraction::Nextcloud::Internal::DeleteEntityCommand)

        result.match(
          on_failure: ->(error) { expect(error.code).to eq(:not_found) },
          on_success: ->(response) { fail "Expected failure, got #{response}" }
        )
      end
    end
  end
end
