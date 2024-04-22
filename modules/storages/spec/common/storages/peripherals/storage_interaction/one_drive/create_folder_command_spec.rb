# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::CreateFolderCommand, :vcr, :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:storage) { create(:sharepoint_dev_drive_storage) }
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthClientCredentials.strategy
  end

  it "is registered as commands.one_drive.create_folder" do
    expect(Storages::Peripherals::Registry.resolve("one_drive.commands.create_folder")).to eq(described_class)
  end

  describe "#call" do
    let(:folder_name) { "Földer CreatedBy Çommand" }

    it "responds with correct parameters" do
      expect(described_class).to respond_to(:call)

      method = described_class.method(:call)
      expect(method.parameters).to contain_exactly(%i[keyreq storage],
                                                   %i[keyreq auth_strategy],
                                                   %i[keyreq folder_name],
                                                   %i[keyreq parent_location])
    end

    it "creates a folder in root", vcr: "one_drive/create_folder_root" do
      parent_location = Storages::Peripherals::ParentFolder.new("/")

      result = described_class.call(storage:, auth_strategy:, folder_name:, parent_location:)

      expect(result).to be_success
    ensure
      delete_created_folder(result.result.id)
    end

    it "creates a folder in another folder", vcr: "one_drive/create_folder_parent" do
      parent_location = Storages::Peripherals::ParentFolder.new("01AZJL5PKU2WV3U3RKKFF2A7ZCWVBXRTEU")

      result = described_class.call(storage:, auth_strategy:, folder_name:, parent_location:)

      expect(result).to be_success
    ensure
      delete_created_folder(result.result.id)
    end

    context "if parent location does not exist" do
      it "returns a failure", vcr: "one_drive/create_folder_parent_not_found" do
        parent_location = Storages::Peripherals::ParentFolder.new("01AZJL5PKU2WV3U3RKKFF4A7ZCWVBXRTEU")

        result = described_class.call(storage:, auth_strategy:, folder_name:, parent_location:)

        expect(result).to be_failure
        result.match(
          on_failure: ->(error) do
            expect(error.code).to eq(:not_found)
            expect(error.data.source).to be(described_class)
          end,
          on_success: ->(response) { fail "Expected failure, got #{response}" }
        )
      end
    end

    context "if folder already exists" do
      let(:folder_name) { "Folder" }

      it "returns a success", vcr: "one_drive/create_folder_already_exists" do
        parent_location = Storages::Peripherals::ParentFolder.new("/")

        result = described_class.call(storage:, auth_strategy:, folder_name:, parent_location:)

        expect(result).to be_failure
        expect(result.result).to eq(:already_exists)
        result.match(
          on_failure: ->(error) do
            expect(error.code).to eq(:conflict)
            expect(error.data.source).to be(described_class)
          end,
          on_success: ->(response) { fail "Expected failure, got #{response}" }
        )
      end
    end
  end

  private

  def delete_created_folder(location)
    Storages::Peripherals::Registry
      .resolve("one_drive.commands.delete_folder")
      .call(storage:, auth_strategy:, location:)
  end
end
