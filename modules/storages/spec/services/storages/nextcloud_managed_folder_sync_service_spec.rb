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
  RSpec.describe NextcloudManagedFolderSyncService, :webmock do
    subject(:service) { described_class }

    describe ".call" do
      it "requires a NextcloudStorage to be passed" do
        method = described_class.method(:call)

        expect(method.parameters).to contain_exactly(%i[req storage])
        expect { service.call(OneDriveStorage.new) }
          .to raise_error(ArgumentError, "Expected Storages::NextcloudStorage but got Storages::OneDriveStorage")
      end
    end

    describe "#call" do
      shared_let(:admin) { create(:admin) }
      shared_let(:multiple_projects_user) { create(:user) }
      shared_let(:single_project_user) { create(:user) }
      shared_let(:non_signed_on_user) { create(:user) }

      shared_let(:storage) { create(:nextcloud_storage_with_complete_configuration, :as_automatically_managed) }

      shared_let(:remote_identities) do
        [create(:remote_identity, user: admin, oauth_client: storage.oauth_client, origin_user_id: "admin"),
         create(:remote_identity, user: multiple_projects_user, oauth_client: storage.oauth_client,
                                  origin_user_id: "multiple_projects_user"),
         create(:remote_identity, user: single_project_user, oauth_client: storage.oauth_client,
                                  origin_user_id: "single_project_user")]
      end

      shared_let(:non_member_role) { create(:non_member, permissions: ["read_files"]) }
      shared_let(:ordinary_role) { create(:project_role, permissions: %w[read_files write_files]) }

      shared_let(:public_project) { create(:public_project, name: "PUBLIC PROJECT") }
      shared_let(:inactive_project) do
        create(:project, :archived, name: "INACTIVE PROJECT", members: { multiple_projects_user => ordinary_role })
      end
      shared_let(:project) do
        create(:project, name: "[Sample] Project Name / Ehüu ///",
                         members: { multiple_projects_user => ordinary_role, single_project_user => ordinary_role })
      end
      shared_let(:renamed_project) do
        create(:project, name: "Renamed Project #23",
                         members: { multiple_projects_user => ordinary_role })
      end

      let!(:public_storage) { create(:project_storage, :as_automatically_managed, storage:, project: public_project) }
      let!(:project_storage) { create(:project_storage, :as_automatically_managed, storage:, project:) }

      let!(:inactive_storage) do
        create(:project_storage, :as_automatically_managed, :with_historical_data,
               storage:, project: inactive_project, project_folder_id: "12345")
      end
      let!(:renamed_storage) do
        create(:project_storage, :as_automatically_managed, :with_historical_data,
               storage:, project: renamed_project, project_folder_id: "9001")
      end

      let(:file_ids) { class_double(Peripherals::StorageInteraction::Nextcloud::FileIdsQuery) }
      let(:group_users) { class_double(Peripherals::StorageInteraction::Nextcloud::GroupUsersQuery) }
      let(:rename_file) { class_double(Peripherals::StorageInteraction::Nextcloud::RenameFileCommand) }
      let(:set_permissions) { class_double(Peripherals::StorageInteraction::Nextcloud::SetPermissionsCommand) }
      let(:create_folder) { class_double(Peripherals::StorageInteraction::Nextcloud::CreateFolderCommand) }
      let(:add_user) { class_double(Peripherals::StorageInteraction::Nextcloud::AddUserToGroupCommand) }
      let(:remove_user) { class_double(Peripherals::StorageInteraction::Nextcloud::RemoveUserFromGroupCommand) }
      let(:auth_strategy) { Peripherals::StorageInteraction::AuthenticationStrategies::Strategy.new(key: :basic_auth) }

      let(:file_ids_result) do
        ServiceResult.success(
          result: { inactive_storage.managed_project_folder_path => { "fileid" => "12345" },
                    "/OpenProject/Another Name for this Project" => { "fileid" => "9001" } }
        )
      end

      let(:group_users_result) do
        ServiceResult.success(result: %w[OpenProject admin multiple_projects_user cookiemonster])
      end

      let(:group_permissions_result) { ServiceResult.success }
      let(:group_permissions) { { groups: { OpenProject: 1 }, users: { OpenProject: 31 } } }

      let(:projects_folder_permissions) { build_project_folder_permissions }

      let(:rename_file_result) do
        StorageFile.new(id: renamed_storage.project_folder_id, name: renamed_storage.managed_project_folder_name,
                        location: renamed_storage.managed_project_folder_path)
      end

      let(:remove_user_result) { ServiceResult.success }
      let(:add_user_result) { ServiceResult.success }

      let(:parent_location) { Peripherals::ParentFolder.new("/") }
      let(:create_folder_result) { build_create_folder_result }

      before do
        Peripherals::Registry.stub("nextcloud.queries.file_ids", file_ids)
        Peripherals::Registry.stub("nextcloud.queries.group_users", group_users)
        Peripherals::Registry.stub("nextcloud.commands.add_user_to_group", add_user)
        Peripherals::Registry.stub("nextcloud.commands.create_folder", create_folder)
        Peripherals::Registry.stub("nextcloud.commands.remove_user_from_group", remove_user)
        Peripherals::Registry.stub("nextcloud.commands.rename_file", rename_file)
        Peripherals::Registry.stub("nextcloud.commands.set_permissions", set_permissions)
        Peripherals::Registry.stub("nextcloud.authentication.userless", -> { auth_strategy })

        # We arent using ParentFolder nor AuthStrategies on FileIds
        allow(file_ids).to receive(:call).with(storage:, path: storage.group).and_return(file_ids_result)
        # Setting the Group Permissions
        allow(set_permissions)
          .to receive(:call).with(storage:, auth_strategy:, path: storage.group,
                                  permissions: group_permissions).and_return(group_permissions_result)

        # Creating folders
        allow(create_folder).to receive(:call).with(storage:, auth_strategy:, parent_location:,
                                                    folder_name: project_storage.managed_project_folder_path)
                                              .and_return(create_folder_result[project_storage.managed_project_folder_name])

        allow(create_folder).to receive(:call).with(storage:, auth_strategy:, parent_location:,
                                                    folder_name: public_storage.managed_project_folder_path)
                                              .and_return(create_folder_result[public_storage.managed_project_folder_name])

        # Renaming folders
        allow(rename_file).to receive(:call).with(storage:, auth_strategy:, file_id: renamed_storage.project_folder_id,
                                                  name: renamed_storage.managed_project_folder_name)
                                            .and_return(ServiceResult.success(result: rename_file_result))

        # Project Permissions + Hiding Projects
        projects_folder_permissions.each_pair do |path, permissions|
          allow(set_permissions).to receive(:call).with(storage:, auth_strategy:, path:, permissions:)
                                                  .and_return(ServiceResult.success)
        end

        # No AuthStrategy on GroupUsers
        allow(group_users).to receive(:call).with(storage:, group: storage.group).and_return(group_users_result)
        # Updating the group users
        allow(add_user).to receive(:call).with(storage:, user: "single_project_user").and_return(add_user_result)
        allow(remove_user).to receive(:call).with(storage:, user: "cookiemonster").and_return(remove_user_result)
      end

      it "applies changes to all project storages linked to the passed storage" do
        expect { service.call(storage) }.to change(LastProjectFolder, :count).by(2)
        expect(set_permissions).to have_received(:call).exactly(5).times
      end

      context "when a project is renamed" do
        let(:file_ids_result) do
          ServiceResult.success(result: { "OBVIOUSLY NON RENAMED" => { "fileid" => renamed_storage.project_folder_id } })
        end

        let(:group_users_result) do
          ServiceResult.success(result: %w[OpenProject admin single_project_user multiple_projects_user])
        end

        before { ProjectStorage.where.not(id: renamed_storage.id).delete_all }

        it "requests to rename the folder to the new managed folder name" do
          service.call(storage)
          expect(rename_file).to have_received(:call)
                                   .with(storage:, auth_strategy:, file_id: renamed_storage.project_folder_id,
                                         name: renamed_storage.managed_project_folder_name).once
        end
      end

      context "with a public project" do
        let(:file_ids_result) { ServiceResult.success(result: {}) }

        let(:permissions) do
          { groups: { OpenProject: 0 },
            users: { "OpenProject" => 31, "admin" => 31, "single_project_user" => 1, "multiple_projects_user" => 1 } }
        end

        before { ProjectStorage.where.not(id: public_storage.id).delete_all }

        it "allows sets permissions to all signed-in users" do
          service.call(storage)
          expect(set_permissions).to have_received(:call).with(storage:, auth_strategy:, permissions:,
                                                               path: public_storage.managed_project_folder_path).once
        end
      end

      context "with a project with trailing slashes" do
        it "replaces the offending characters"
        it "updates the project storage with the remote folder id"
        it "adds a new entry on historical data"
      end

      context "with a project with special characters"

      context "with an archived project" do
        it "hides the project folder"
      end

      context "when errors happen" do
        it "logs the occurrence"
        it "adds the errors to the result"
      end
    end

    private

    def build_create_folder_result
      {
        public_storage.managed_project_folder_name => ServiceResult.success(result:
          StorageFile.new(id: "public_id", name: public_storage.managed_project_folder_name)),
        project_storage.managed_project_folder_name => ServiceResult.success(result:
          StorageFile.new(id: "normal_project_id", name: project_storage.managed_project_folder_name))
      }
    end

    def build_project_folder_permissions
      {
        inactive_storage.managed_project_folder_path => { groups: { OpenProject: 0 }, users: { OpenProject: 31 } },
        public_storage.managed_project_folder_path => { groups: { OpenProject: 0 },
                                                        users: { "OpenProject" => 31, "admin" => 31, "single_project_user" => 1,
                                                                 "multiple_projects_user" => 1 } },
        project_storage.managed_project_folder_path => { groups: { OpenProject: 0 },
                                                         users: { "OpenProject" => 31, "admin" => 31,
                                                                  "multiple_projects_user" => 3, "single_project_user" => 3 } },
        renamed_storage.managed_project_folder_path => { groups: { OpenProject: 0 },
                                                         users: { "OpenProject" => 31, "admin" => 31,
                                                                  "multiple_projects_user" => 3 } }
      }
    end
  end
end
# RSpec.describe Storages::NextcloudManagedFolderSyncService, :webmock do
#   let(:project_with_special_characters) do
#     create(:project, name: "[Sample] Project Name / Ehüu",
#                      members: { multiple_projects_user => ordinary_role, single_project_user => ordinary_role })
#   end
#
#   let(:project_with_trailing_slashes) do
#     create(:project, name: "Jedi Project Folder ///", members: { multiple_projects_user => ordinary_role })
#   end
#
#   let(:project) do
#     create(:project, name: "Project 3", members: { multiple_projects_user => ordinary_role })
#   end
#
#   let(:inactive_project) do
#     create(:project, :archived, name: "NOT ACTIVE PROJECT", members: { multiple_projects_user => ordinary_role })
#   end
#
#   let(:public_project) do
#     create(:public_project, name: "PUBLIC PROJECT", active: true)
#   end
#
#   let(:single_project_user) { create(:user) }
#   let(:multiple_projects_user) { create(:user) }
#   let(:admin) { create(:admin) }
#
#   let(:ordinary_role) { create(:project_role, permissions: %w[read_files write_files]) }
#   let(:non_member_role) { create(:non_member, permissions: %w[read_files]) }
#
#   let(:storage) { create(:nextcloud_storage, :with_oauth_client, :as_automatically_managed, password: "12345678") }
#
#   let(:project_storage) do
#     create(:project_storage, :with_historical_data, :as_automatically_managed, project: project_with_special_characters,
#   storage:)
#   end
#
#   let(:project_storage2) do
#     create(:project_storage, :with_historical_data, :as_automatically_managed,
#            project: project_with_trailing_slashes, storage:, project_folder_id: "123")
#   end
#   let(:project_storage3) do
#     create(:project_storage, :with_historical_data, :as_automatically_managed, project:, storage:, project_folder_id: "2600003")
#   end
#
#   let(:project_storage4) do
#     create(:project_storage, :with_historical_data, :as_automatically_managed,
#            project: inactive_project, storage:, project_folder_id: "778")
#   end
#
#   let(:project_storage5) do
#     create(:project_storage, :with_historical_data, :as_automatically_managed,
#            project: public_project, storage:, project_folder_id: "999")
#   end
#
#   let(:oauth_client) { storage.oauth_client }
#
#   let(:prefix) { "services.errors.models.nextcloud_sync_service" }
#
#   describe "#call" do
#   before do
#     create(:remote_identity, origin_user_id: "Obi-Wan", user: multiple_projects_user, oauth_client:)
#     create(:remote_identity, origin_user_id: "Yoda", user: single_project_user, oauth_client:)
#     create(:remote_identity, origin_user_id: "Darth Vader", user: admin, oauth_client:)
#   end
#
#   it "sets project folders properties" do
#     expect(project_storage1.project_folder_id).to be_nil
#     expect(project_storage2.project_folder_id).to eq("123")
#     expect(project_storage3.project_folder_id).to eq("2600003")
#
#     expect(project_storage1.last_project_folders.pluck(:origin_folder_id)).to eq([nil])
#     expect(project_storage2.last_project_folders.pluck(:origin_folder_id)).to eq(["123"])
#     expect(project_storage3.last_project_folders.pluck(:origin_folder_id)).to eq(["2600003"])
#
#     described_class.new(storage).call
#
#     expect(project_storage1.reload.project_folder_id).to eq("819")
#     expect(project_storage2.reload.project_folder_id).to eq("123")
#     expect(project_storage3.reload.project_folder_id).to eq("2600003")
#
#     expect(project_storage1.last_project_folders.pluck(:origin_folder_id)).to eq(["819"])
#     expect(project_storage2.last_project_folders.pluck(:origin_folder_id)).to eq(["123"])
#     expect(project_storage3.last_project_folders.pluck(:origin_folder_id)).to eq(["2600003"])
#
#     expect_all_stubs
#   end
#
#   describe "error handling and flow control" do
#     context "when getting the root folder properties fail" do
#       context "on a handled error case" do
#         it "stops the flow immediately if the response is anything but a success" do
#           described_class.new(storage).call
#
#           request_stubs[1..].each { |request| expect(request).not_to have_been_requested }
#         end
#
#         it "logs an error message" do
#           allow(Rails.logger).to receive(:error)
#           described_class.new(storage).call
#
#           expect(Rails.logger)
#             .to have_received(:error)
#             .with(folder: "OpenProject", error_code: :not_found, data: { status: 404, body: "" }, message: /not found/)
#         end
#
#         it "returns a failure" do
#           result = described_class.new(storage).call
#
#           expect(result).to be_failure
#           expect(result.errors[:remote_folders])
#             .to contain_exactly(I18n.t("#{prefix}.attributes.remote_folders.not_found",
#                                        group_folder: storage.group_folder))
#         end
#       end
#
#       it "raises an error when dealing with an unhandled error case" do
#         expect(described_class.new(storage).call).to be_failure
#       end
#
#       it "raises an error when dealing with a socket or connection error" do
#         expect(described_class.new(storage).call).to be_failure
#       end
#     end
#
#     context "when setting the root folder permissions fail" do
#       context "on a handled error case" do
#         it "interrupts the flow" do
#           described_class.new(storage).call
#
#           expect(request_stubs[0..1]).to all(have_been_requested)
#           request_stubs[2..].each { |request| expect(request).not_to have_been_requested }
#         end
#
#         it "logs an error message" do
#           allow(Rails.logger).to receive(:error)
#           described_class.new(storage).call
#
#           expect(Rails.logger)
#             .to have_received(:error)
#             .with(folder: "OpenProject",
#                   message: /not authorized/,
#                   error_code: :unauthorized,
#                   data: { status: 401, body: "Heute nicht" })
#         end
#
#         it "returns a failure" do
#           result = described_class.new(storage).call
#
#           expect(result).to be_failure
#           expect(result.errors[:base]).to contain_exactly(I18n.t("#{prefix}.unauthorized"))
#         end
#       end
#     end
#
#     context "when folder creation fails" do
#       it "continues normally ignoring that folder" do
#         expect { described_class.new(storage).call }.not_to change(project_storage1, :project_folder_id)
#
#         expect(request_stubs[..2]).to all(have_been_requested)
#         expect(request_stubs[3]).not_to have_been_requested
#         expect(request_stubs[4]).to have_been_made.times(2)
#         expect(request_stubs[5]).to have_been_requested
#         expect(request_stubs[6]).not_to have_been_requested
#         expect(request_stubs[7..]).to all(have_been_requested)
#       end
#
#       it "logs the occurrence" do
#         allow(Rails.logger).to receive(:error)
#         described_class.new(storage).call
#
#         expect(Rails.logger)
#           .to have_received(:error)
#           .with(folder_name: "/OpenProject/[Sample] Project Name | Ehuu (#{project1.id})/",
#                 message: /not found/,
#                 error_code: :not_found,
#                 data: "not found")
#       end
#     end
#
#     context "when renaming a folder fail" do
#       it "we stop processing to avoid issues with permissions" do
#         described_class.new(storage).call
#         request_stubs[6..].each { |request| expect(request).not_to have_been_requested }
#       end
#
#       it "logs the occurrence" do
#         allow(Rails.logger).to receive(:error)
#         described_class.new(storage).call
#
#         expect(Rails.logger)
#           .to have_received(:error)
#           .with(folder_id: project_storage2.project_folder_id,
#                 error_code: :not_found,
#                 message: /not found/,
#                 folder_name: "Jedi Project Folder ||| (#{project2.id})",
#                 data: { status: 404, body: "" })
#       end
#     end
#
#     context "when hiding a folder fail" do
#       before do
#         request_stubs[6] = stub_request(:proppatch,
#                                         "#{storage.host}remote.php/dav/files/OpenProject/OpenProject/" \
#                                         "Lost%20Jedi%20Project%20Folder%20%232")
#                            .with(body: hide_folder_set_permissions_request_body,
#                                  headers: {
#                                    "Authorization" => "Basic T3BlblByb2plY3Q6MTIzNDU2Nzg="
#                                  })
#                            .to_return(status: 500, body: "A server error occurred", headers: {})
#       end
#
#       it "does not interrupt the flow" do
#         described_class.new(storage).call
#
#         expect_all_stubs
#       end
#
#       it "logs the occurrence" do
#         allow(Rails.logger).to receive(:error)
#         described_class.new(storage).call
#
#         expect(Rails.logger)
#           .to have_received(:error)
#           .with(context: "hide_folder",
#                 folder: "/OpenProject/Lost Jedi Project Folder #2/",
#                 message: /request failed/,
#                 error_code: :error,
#                 data: { status: 500, body: "A server error occurred" })
#       end
#     end
#
#     context "when setting project folder permissions fail" do
#       before do
#         request_stubs[8] = stub_request(:proppatch,
#                                         "#{storage.host}remote.php/dav/files/OpenProject/OpenProject/" \
#                                         "Jedi%20Project%20Folder%20%7C%7C%7C%20%28#{project2.id}%29")
#                            .with(body: set_permissions_request_body,
#                                  headers: { "Authorization" => "Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=" })
#                            .to_return(status: 500,
#                                       body: "Divide by cucumber error. Please reinstall universe and reboot.",
#                                       headers: {})
#       end
#
#       it "does not interrupt the flow" do
#         described_class.new(storage).call
#
#         expect_all_stubs
#       end
#
#       it "logs the occurrence" do
#         allow(Rails.logger).to receive(:error)
#         described_class.new(storage).call
#
#         expect(Rails.logger)
#           .to have_received(:error)
#           .with(folder: "/OpenProject/Jedi Project Folder ||| (#{project2.id})/",
#                 message: /failed/,
#                 error_code: :error,
#                 data: { status: 500, body: "Divide by cucumber error. Please reinstall universe and reboot." })
#       end
#     end
#
#     context "when adding a user to the group fails" do
#       before do
#         request_stubs[12] = stub_request(:post, "#{storage.host}ocs/v1.php/cloud/users/Obi-Wan/groups")
#                             .with(
#                               body: "groupid=OpenProject",
#                               headers: {
#                                 "Authorization" => "Basic T3BlblByb2plY3Q6MTIzNDU2Nzg=",
#                                 "Ocs-Apirequest" => "true"
#                               }
#                             ).to_return(status: 302, body: "", headers: {})
#       end
#
#       it "does not interrupt te flow" do
#         described_class.new(storage).call
#
#         expect_all_stubs
#       end
#
#       it "logs the occurrence" do
#         allow(Rails.logger).to receive(:error)
#         described_class.new(storage).call
#
#         expect(Rails.logger)
#           .to have_received(:error)
#           .with(group: "OpenProject",
#                 user: "Obi-Wan",
#                 message: /failed/,
#                 error_code: :error,
#                 reason: "Outbound request failed",
#                 data: { status: 302, body: "" })
#       end
#     end
#
#     context "when removing a user to the group fails" do
#       let(:remove_user_from_group_response) do
#         <<~XML
#           <?xml version="1.0"?>
#           <ocs>
#               <meta>
#                   <status>failure</status>
#                   <statuscode>105</statuscode>
#                   <message>Not viable to remove user from the last group you are SubAdmin of</message>
#               </meta>
#               <data/>
#           </ocs>
#         XML
#       end
#
#       it "does not interrupt the flow" do
#         described_class.new(storage).call
#       end
#
#       it "logs the occurrence and continues the flow" do
#         allow(Rails.logger).to receive(:error)
#         described_class.new(storage).call
#
#         expect(Rails.logger)
#           .to have_received(:error)
#           .with(group: "OpenProject",
#                 user: "Darth Maul",
#                 message: /SubAdmin/,
#                 error_code: :failed_to_remove,
#                 reason: /SubAdmin/,
#                 data: { status: 200, body: remove_user_from_group_response })
#       end
#     end
#   end
# end
# end
