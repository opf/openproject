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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::SetPermissionsCommand, :webmock do
  let(:storage) do
    create(:sharepoint_dev_drive_storage,
           drive_id: "b!dmVLG22QlE2PSW0AqVB7UOhZ8n7tjkVGkgqLNnuw2ODRDvn3haLiQIhB5UYNdqMy")
  end

  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthClientCredentials.new(false)
  end

  let(:permissions_command) { described_class.new(storage) }

  let(:folder) do
    Storages::Peripherals::Registry
      .resolve("one_drive.commands.create_folder")
      .call(storage:,
            auth_strategy:,
            folder_name: "Permission Test Folder",
            parent_location: Storages::Peripherals::ParentFolder.new("/"))
      .result
  end

  let(:path) { folder.id }

  it_behaves_like "set_permissions_command: basic command setup"

  it_behaves_like "set_permissions_command: validating input data"

  describe "#call" do
    after do
      Storages::Peripherals::Registry
        .resolve("one_drive.commands.delete_folder")
        .call(storage:, auth_strategy:, location: path)
    end

    context "when trying to access a non-existing driveItem" do
      it "returns a failure", vcr: "one_drive/set_permissions_not_found_folder" do
        input_data = input_data(file_id: "THIS_IS_NOT_THE_FOLDER_YOURE_LOOKING_FOR", permissions: {})
        result = permissions_command.call(auth_strategy:, input_data:)

        expect(result).to be_failure
        expect(result.result).to eq(:not_found)
      end
    end

    context "when a permission set already exists" do
      it "replaces the write permission grant with the provided list",
         vcr: "one_drive/set_permissions_replace_permissions_write" do
        input_data = input_data(file_id: folder.id,
                                permissions: { "84acc1d5-61be-470b-9d79-0d1f105c2c5f": { write_files: true } })
        permissions_command.call(auth_strategy:, input_data:)
        expect(user_list("write")).to match_array("84acc1d5-61be-470b-9d79-0d1f105c2c5f")

        input_data = input_data(file_id: folder.id,
                                permissions: { "d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce": { write_files: true } })
        permissions_command.call(auth_strategy:, input_data:)
        expect(user_list("write")).to match_array("d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce")
      end

      it "replaces the read permission grant with the provided list",
         vcr: "one_drive/set_permissions_replace_permissions_read" do
        input_data = input_data(file_id: folder.id,
                                permissions: { "84acc1d5-61be-470b-9d79-0d1f105c2c5f": { read_files: true } })
        permissions_command.call(auth_strategy:, input_data:)
        expect(user_list("read")).to match_array("84acc1d5-61be-470b-9d79-0d1f105c2c5f")

        input_data = input_data(file_id: folder.id,
                                permissions: { "d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce": { read_files: true } })
        permissions_command.call(auth_strategy:, input_data:)
        expect(user_list("read")).to match_array("d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce")
      end
    end

    context "when no expected permission exists" do
      it "creates the write permission", vcr: "one_drive/set_permissions_create_permission_write" do
        current_roles = remote_permissions.map { |permission| permission[:roles].first }
        expect(current_roles).not_to include("write")

        input_data = input_data(file_id: folder.id,
                                permissions: { "d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce": { write_files: true } })
        permissions_command.call(auth_strategy:, input_data:)

        current_roles = remote_permissions.map { |permission| permission[:roles].first }
        expect(current_roles).to include("write")
      end

      it "creates the read permission", vcr: "one_drive/set_permissions_create_permission_read" do
        current_roles = remote_permissions.map { |permission| permission[:roles].first }
        expect(current_roles).not_to include("read")

        input_data = input_data(file_id: folder.id,
                                permissions: { "d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce": { read_files: true } })
        permissions_command.call(auth_strategy:, input_data:)

        current_roles = remote_permissions.map { |permission| permission[:roles].first }
        expect(current_roles).to include("read")
      end
    end

    context "when there are no user to set permissions" do
      it "deletes the write permission", vcr: "one_drive/set_permissions_delete_permission_write" do
        input_data = input_data(file_id: folder.id,
                                permissions: { "d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce": { write_files: true } })
        permissions_command.call(auth_strategy:, input_data:)
        current_roles = remote_permissions.map { |permission| permission[:roles].first }
        expect(current_roles).to include("write")

        permissions_command.call(auth_strategy:, input_data: input_data(file_id: folder.id, permissions: {}))

        current_roles = remote_permissions.map { |permission| permission[:roles].first }
        expect(current_roles).not_to include("write")
      end

      it "deletes the read permission", vcr: "one_drive/set_permissions_delete_permission_read" do
        input_data = input_data(file_id: folder.id,
                                permissions: { "d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce": { read_files: true } })
        permissions_command.call(auth_strategy:, input_data:)
        current_roles = remote_permissions.map { |permission| permission[:roles].first }
        expect(current_roles).to include("read")

        permissions_command.call(auth_strategy:, input_data: input_data(file_id: folder.id, permissions: {}))

        current_roles = remote_permissions.map { |permission| permission[:roles].first }
        expect(current_roles).not_to include("read")
      end
    end

    context "when there is a timeout" do
      it "logs a warning and does not raise NoMethodError", vcr: "one_drive/set_permissions_delete_permission_read" do
        stub_request_with_timeout(:post, /invite$/)
        allow(Rails.logger).to receive(:error)

        input_data = input_data(file_id: folder.id,
                                permissions: { "d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce": { read_files: true } })
        permissions_command.call(auth_strategy:, input_data:)

        # rubocop:disable Layout/LineLength
        expect(Rails.logger)
          .to have_received(:error)
                .with(
                  error_code: :error,
                  message: nil,
                  data: %r{/lib/httpx/response.rb:260:in `full_message': timed out while waiting on select \(HTTPX::ConnectTimeoutError\)\n$}
                ).once
        # rubocop:enable Layout/LineLength
      end
    end
  end

  private

  def input_data(file_id:, permissions:)
    Storages::Peripherals::StorageInteraction::Inputs::SetPermissions.new(file_id:, permissions:)
  end

  def user_list(role)
    remote_permissions
      .select { |item| item[:roles].first == role }
      .map { |grant| grant.dig(:grantedToV2, :user, :id) }
  end

  def remote_permissions
    Storages::Peripherals::StorageInteraction::OneDrive::Util.using_admin_token(storage) do |http|
      http.get("/v1.0/drives/#{storage.drive_id}/items/#{path}/permissions")
          .raise_for_status
          .json(symbolize_keys: true)
          .fetch(:value)
    end
  end

  def auth_strategy
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthClientCredentials.strategy
  end
end
