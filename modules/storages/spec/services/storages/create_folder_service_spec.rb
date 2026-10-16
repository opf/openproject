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

module Storages
  RSpec.describe CreateFolderService do
    let(:user) { create(:admin) }
    let(:parent_file_info) do
      Adapters::Results::StorageFileInfo.build(
        status: "OK",
        status_code: 200,
        id: SecureRandom.hex,
        name: "/",
        location: "/Path/To/Parent/Next"
      ).value!
    end

    let(:folder_name) { "TestFolderName" }
    let(:parent_id) { parent_file_info.id }
    let(:auth_strategy) { Adapters::Registry["#{storage}.authentication.user_bound"].call(user, storage) }

    let(:create_folder_input) do
      Adapters::Input::CreateFolder.build(folder_name:, parent_location: parent_file_info.id).value!
    end

    subject(:service) { described_class.new(storage) }

    before do
      Adapters::Registry.stub("#{storage}.commands.create_folder", create_folder_command)
      allow(create_folder_command).to receive(:call).and_return(Success("AwesomeFolderInfo"))
    end

    context "when storage is nextcloud" do
      let(:storage) { create(:nextcloud_storage) }

      let(:create_folder_input) do
        # FIXME: Nextcloud uses the path and not the parent ID as the location. This is prime target for refactor.
        Adapters::Input::CreateFolder.build(folder_name:, parent_location: parent_file_info.location).value!
      end

      let(:create_folder_command) { class_double(Adapters::Providers::Nextcloud::Commands::CreateFolderCommand) }

      before do
        allow(StorageFileService)
          .to receive(:call).with(storage:, user:, file_id: parent_id)
                            .and_return(ServiceResult.success(result: parent_file_info))
      end

      it "calls the appropriate command with the expected parameters" do
        service.call(user:, folder_name:, parent_id:)

        expect(create_folder_command)
          .to have_received(:call).with(storage:, auth_strategy:, input_data: create_folder_input).once
      end
    end

    context "when storage is onedrive" do
      let(:storage) { create(:onedrive_storage) }
      let(:parent_id) { parent_file_info.id }
      let(:create_folder_command) { class_double(Adapters::Providers::OneDrive::Commands::CreateFolderCommand) }

      it "calls the appropriate command with the expected parameters" do
        service.call(user:, folder_name:, parent_id:)

        expect(create_folder_command)
          .to have_received(:call).with(storage:, auth_strategy:, input_data: create_folder_input).once
      end
    end

    context "when storage is sharepoint" do
      let(:storage) { create(:sharepoint_storage) }
      let(:parent_id) { parent_file_info.id }
      let(:create_folder_command) { class_double(Adapters::Providers::Sharepoint::Commands::CreateFolderCommand) }

      it "calls the appropriate command with the expected parameters" do
        service.call(user:, folder_name:, parent_id:)

        expect(create_folder_command)
          .to have_received(:call).with(storage:, auth_strategy:, input_data: create_folder_input).once
      end
    end
  end
end
