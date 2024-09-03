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
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthClientCredentials
      .strategy
      .with_cache(false)
  end

  let(:test_folder) do
    Storages::Peripherals::Registry
      .resolve("one_drive.commands.create_folder")
      .call(storage:,
            auth_strategy:,
            folder_name: "Permission Test Folder",
            parent_location: Storages::Peripherals::ParentFolder.new("/"))
      .result
  end

  it_behaves_like "set_permissions_command: basic command setup"

  context "if file does not exists", vcr: "one_drive/set_permissions_not_found_folder" do
    let(:error_source) { described_class }
    let(:input_data) { permission_input_data("THIS_IS_NOT_THE_FOLDER_YOURE_LOOKING_FOR", []) }

    it_behaves_like "set_permissions_command: not found"
  end

  context "if a write roles is already set" do
    def current_remote_permissions
      permission_list_from_role("write")
    end

    context "and new write permissions should be set", vcr: "one_drive/set_permissions_replace_permissions_write" do
      let(:previous_permissions) { [{ user_id: "84acc1d5-61be-470b-9d79-0d1f105c2c5f", permissions: [:write_files] }] }
      let(:replacing_permissions) { [{ user_id: "d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce", permissions: [:write_files] }] }

      it_behaves_like "set_permissions_command: replaces already set permissions"
    end

    context "and they should get deleted", vcr: "one_drive/set_permissions_delete_permission_write" do
      let(:previous_permissions) { [{ user_id: "d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce", permissions: [:write_files] }] }
      let(:replacing_permissions) { [] }

      it_behaves_like "set_permissions_command: replaces already set permissions"
    end
  end

  context "if a read roles is already set", vcr: "one_drive/set_permissions_replace_permissions_read" do
    def current_remote_permissions
      permission_list_from_role("read")
    end

    context "and new read permissions should be set", vcr: "one_drive/set_permissions_replace_permissions_read" do
      let(:previous_permissions) { [{ user_id: "84acc1d5-61be-470b-9d79-0d1f105c2c5f", permissions: [:read_files] }] }
      let(:replacing_permissions) { [{ user_id: "d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce", permissions: [:read_files] }] }

      it_behaves_like "set_permissions_command: replaces already set permissions"
    end

    context "and they should get deleted", vcr: "one_drive/set_permissions_delete_permission_read" do
      let(:previous_permissions) { [{ user_id: "d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce", permissions: [:read_files] }] }
      let(:replacing_permissions) { [] }

      it_behaves_like "set_permissions_command: replaces already set permissions"
    end
  end

  context "if no write permission exists", vcr: "one_drive/set_permissions_create_permission_write" do
    let(:user_permissions) { [{ user_id: "d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce", permissions: [:write_files] }] }

    def current_remote_permissions
      permission_list_from_role("write")
    end

    it_behaves_like "set_permissions_command: creates new permissions"
  end

  context "if no read permission exists", vcr: "one_drive/set_permissions_create_permission_read" do
    let(:user_permissions) { [{ user_id: "d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce", permissions: [:read_files] }] }

    def current_remote_permissions
      permission_list_from_role("read")
    end

    it_behaves_like "set_permissions_command: creates new permissions"
  end

  context "if a timeout occurs" do
    it "logs an error", vcr: "one_drive/set_permissions_delete_permission_read" do
      stub_request_with_timeout(:post, /invite$/)
      allow(Rails.logger).to receive(:error)

      user_permissions = [{ user_id: "d6e00f6d-1ae7-43e6-b0af-15d99a56d4ce", permissions: [:read_files] }]
      input_data = permission_input_data(test_folder.id, user_permissions)
      described_class.call(storage:, auth_strategy:, input_data:)

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

  private

  def permission_input_data(file_id, user_permissions)
    Storages::Peripherals::StorageInteraction::Inputs::SetPermissions.build(file_id:, user_permissions:).value!
  end

  def clean_up(file_id)
    Storages::Peripherals::Registry
      .resolve("one_drive.commands.delete_folder")
      .call(storage:, auth_strategy:, location: file_id)
  end

  def permission_list_from_role(role)
    perm = role == "write" ? :write_files : :read_files

    remote_permissions
      .select { |item| item[:roles].first == role }
      .map { |grant| grant.dig(:grantedToV2, :user, :id) }
      .map { |id| { user_id: id, permissions: [perm] } }
  end

  def remote_permissions
    Storages::Peripherals::StorageInteraction::Authentication[auth_strategy].call(storage:) do |http|
      http.get(Storages::UrlBuilder.url(storage.uri,
                                        "/v1.0/drives",
                                        storage.drive_id,
                                        "/items",
                                        test_folder.id,
                                        "/permissions"))
          .raise_for_status
          .json(symbolize_keys: true)
          .fetch(:value)
    end
  end
end
