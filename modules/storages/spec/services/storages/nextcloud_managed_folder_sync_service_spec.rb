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
         create(:remote_identity,
                user: multiple_projects_user,
                oauth_client: storage.oauth_client,
                origin_user_id: "multiple_projects_user"),
         create(:remote_identity,
                user: single_project_user,
                oauth_client: storage.oauth_client,
                origin_user_id: "single_project_user")]
      end

      shared_let(:non_member_role) { create(:non_member, permissions: ["read_files"]) }
      shared_let(:ordinary_role) { create(:project_role, permissions: %w[read_files write_files]) }

      shared_let(:public_project) { create(:public_project, name: "PUBLIC PROJECT") }
      shared_let(:inactive_project) do
        create(:project, :archived, name: "INACTIVE PROJECT", members: { multiple_projects_user => ordinary_role })
      end
      shared_let(:project) do
        create(:project,
               name: "[Sample] Project Name / Ehüu ///",
               members: { multiple_projects_user => ordinary_role, single_project_user => ordinary_role })
      end
      shared_let(:renamed_project) do
        create(:project,
               name: "Renamed Project #23",
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

      let(:file_path_to_id_map) { class_double(Peripherals::StorageInteraction::Nextcloud::FilePathToIdMapQuery) }
      let(:group_users) { class_double(Peripherals::StorageInteraction::Nextcloud::GroupUsersQuery) }
      let(:rename_file) { class_double(Peripherals::StorageInteraction::Nextcloud::RenameFileCommand) }
      let(:set_permissions) { class_double(Peripherals::StorageInteraction::Nextcloud::SetPermissionsCommand) }
      let(:create_folder) { class_double(Peripherals::StorageInteraction::Nextcloud::CreateFolderCommand) }
      let(:add_user) { class_double(Peripherals::StorageInteraction::Nextcloud::AddUserToGroupCommand) }
      let(:remove_user) { class_double(Peripherals::StorageInteraction::Nextcloud::RemoveUserFromGroupCommand) }
      let(:auth_strategy) { Peripherals::StorageInteraction::AuthenticationStrategies::Strategy.new(key: :basic_auth) }

      let(:root_folder_id) { "root_folder_id" }
      let(:file_path_to_id_map_result) do
        inactive_storage_path = inactive_storage.managed_project_folder_path.chomp("/")

        ServiceResult.success(
          result: {
            "/OpenProject" => StorageFileId.new(root_folder_id),
            inactive_storage_path => StorageFileId.new(inactive_storage.project_folder_id),
            "/OpenProject/Another Name for this Project" => StorageFileId.new(renamed_storage.project_folder_id)
          }
        )
      end

      let(:group_users_result) do
        ServiceResult.success(result: %w[OpenProject admin multiple_projects_user cookiemonster])
      end

      let(:root_permissions_result) { ServiceResult.success }
      let(:root_permission_input) do
        build_input_data(
          "root_folder_id",
          [
            { user_id: "OpenProject", permissions: OpenProject::Storages::Engine.external_file_permissions },
            { group_id: "OpenProject", permissions: %i[read_files] }
          ]
        )
      end

      let(:projects_folder_permissions) { build_project_folder_permission_input }

      let(:rename_file_result) do
        StorageFile.new(id: renamed_storage.project_folder_id, name: renamed_storage.managed_project_folder_name,
                        location: renamed_storage.managed_project_folder_path)
      end

      let(:remove_user_result) { ServiceResult.success }
      let(:add_user_result) { ServiceResult.success }

      let(:parent_location) { Peripherals::ParentFolder.new("/") }
      let(:create_folder_result) { build_create_folder_result }

      before do
        Peripherals::Registry.stub("nextcloud.queries.file_path_to_id_map", file_path_to_id_map)
        Peripherals::Registry.stub("nextcloud.queries.group_users", group_users)
        Peripherals::Registry.stub("nextcloud.commands.add_user_to_group", add_user)
        Peripherals::Registry.stub("nextcloud.commands.create_folder", create_folder)
        Peripherals::Registry.stub("nextcloud.commands.remove_user_from_group", remove_user)
        Peripherals::Registry.stub("nextcloud.commands.rename_file", rename_file)
        Peripherals::Registry.stub("nextcloud.commands.set_permissions", set_permissions)
        Peripherals::Registry.stub("nextcloud.authentication.userless", -> { auth_strategy })

        # We arent using ParentFolder nor AuthStrategies on FileIds
        folder = Peripherals::ParentFolder.new(storage.group)
        allow(file_path_to_id_map).to receive(:call).with(storage:, auth_strategy:, folder:, depth: 1)
                                                    .and_return(file_path_to_id_map_result)

        # Setting the Group Permissions
        allow(set_permissions).to receive(:call).with(storage:, auth_strategy:, input_data: root_permission_input)
                                                .and_return(root_permissions_result)

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
        projects_folder_permissions.each do |input_data|
          allow(set_permissions).to receive(:call).with(storage:, auth_strategy:, input_data:)
                                                  .and_return(ServiceResult.success)
        end

        # No AuthStrategy on GroupUsers
        allow(group_users).to receive(:call).with(storage:,
                                                  auth_strategy:,
                                                  group: storage.group)
                                            .and_return(group_users_result)
        # Updating the group users
        allow(add_user).to receive(:call).with(storage:,
                                               auth_strategy:,
                                               user: "single_project_user",
                                               group: storage.group)
                                         .and_return(add_user_result)
        allow(remove_user).to receive(:call).with(storage:,
                                                  auth_strategy:,
                                                  user: "cookiemonster",
                                                  group: storage.group)
                                            .and_return(remove_user_result)
      end

      it "applies changes to all project storages linked to the passed storage" do
        expect { service.call(storage) }.to change(LastProjectFolder, :count).by(2)
        expect(set_permissions).to have_received(:call).exactly(5).times
      end

      it "updates the project storage with the remote folder id" do
        expect { service.call(storage) }.to change { project_storage.reload.project_folder_id }
                                              .from(nil).to("normal_project_id")
      end

      context "when a project is renamed" do
        let(:file_path_to_id_map_result) do
          ServiceResult.success(
            result: {
              "/OpenProject" => StorageFileId.new(root_folder_id),
              "/OpenProject/OBVIOUSLY NON RENAMED" => StorageFileId.new(renamed_storage.project_folder_id)
            }
          )
        end

        let(:group_users_result) do
          ServiceResult.success(result: %w[OpenProject admin single_project_user multiple_projects_user])
        end

        before { ProjectStorage.where.not(id: renamed_storage.id).delete_all }

        it "requests to rename the folder to the new managed folder name" do
          service.call(storage)
          expect(rename_file).to have_received(:call)
                                   .with(storage:,
                                         auth_strategy:,
                                         file_id: renamed_storage.project_folder_id,
                                         name: renamed_storage.managed_project_folder_name).once
        end

        it "does not change the project_folder_id after the rename" do
          expect { service.call(storage) }.not_to change { renamed_storage.reload.project_folder_id }
        end
      end

      context "with a public project" do
        let(:file_path_to_id_map_result) do
          ServiceResult.success(result: { "/OpenProject" => StorageFileId.new(root_folder_id) })
        end

        before { ProjectStorage.where.not(id: public_storage.id).delete_all }

        it "allows sets permissions to all signed-in users" do
          input_data = build_project_folder_permission_input[1] # The permissions for the public project

          service.call(storage)
          expect(set_permissions).to have_received(:call).with(storage:, auth_strategy:, input_data:).once
        end
      end

      context "when creating a folder for a project that with trailing slashes in its name" do
        it "replaces the offending characters" do
          service.call(storage)

          expect(create_folder).to have_received(:call)
                                     .with(storage:, auth_strategy:, parent_location: Peripherals::ParentFolder.new("/"),
                                           folder_name: "/OpenProject/[Sample] Project Name | Ehüu ||| (#{project.id})/").once
        end

        it "adds a new entry on historical data" do
          expect { service.call(storage) }.to change { LastProjectFolder.where(project_storage:).count }.by(1)
        end
      end

      context "with an archived project" do
        it "hides the project folder" do
          input_data = build_project_folder_permission_input[0]
          service.call(storage)

          expect(set_permissions).to have_received(:call).with(storage:, auth_strategy:, input_data:).once
        end
      end

      describe "error handling" do
        let(:error_prefix) { "services.errors.models.nextcloud_sync_service" }

        context "when the initial fetch of remote folders fails" do
          let(:file_path_to_id_map_result) do
            errors = storage_error(:unauthorized,
                                   "error body",
                                   Peripherals::StorageInteraction::Nextcloud::FilePathToIdMapQuery)
            ServiceResult.failure(result: :unauthorized, errors:)
          end

          it "logs an error" do
            allow(Rails.logger).to receive(:error).and_call_original
            service.call(storage)
            expect(Rails.logger)
              .to have_received(:error).with(error_code: :unauthorized, message: "TESTING",
                                             folder: "OpenProject", data: "error body")
          end

          it "adds to the services errors" do
            result = service.call(storage)

            expect(result.errors.size).to eq(1)
            expect(result.errors[:base]).to contain_exactly(I18n.t("#{error_prefix}.unauthorized"))
          end

          it "interrupts the flow" do
            service.call(storage)
            [group_users, add_user, create_folder, remove_user, rename_file, set_permissions].each do |command|
              expect(command).not_to have_received(:call)
            end
          end
        end

        context "when we fail to set the root folder permissions" do
          let(:root_permissions_result) do
            errors = storage_error(:error, "error body", Peripherals::StorageInteraction::Nextcloud::SetPermissionsCommand)
            ServiceResult.failure(result: :unauthorized, errors:)
          end

          it "logs an error" do
            allow(Rails.logger).to receive(:error).and_call_original
            service.call(storage)

            expect(Rails.logger).to have_received(:error)
                                      .with(error_code: :error,
                                            message: "TESTING",
                                            folder: "root",
                                            data: "error body",
                                            root_folder_id: "root_folder_id")
          end

          it "adds to the services errors" do
            result = service.call(storage)

            expect(result.errors.size).to eq(1)
            expect(result.errors[:base]).to contain_exactly(I18n.t("#{error_prefix}.error"))
          end

          it "interrupts the flow" do
            service.call(storage)
            expect(set_permissions).to have_received(:call).once

            [group_users, add_user, create_folder, remove_user, rename_file].each do |command|
              expect(command).not_to have_received(:call)
            end
          end
        end

        context "when creating folders fails" do
          let(:create_folder_result) do
            errors = storage_error(:conflict, "error body", Peripherals::StorageInteraction::Nextcloud::CreateFolderCommand)

            build_create_folder_result
              .merge(project_storage.managed_project_folder_name => ServiceResult.failure(result: :conflict, errors:))
          end

          it "logs an error" do
            allow(Rails.logger).to receive(:error).and_call_original
            service.call(storage)

            expect(Rails.logger).to have_received(:error)
                                      .with(error_code: :conflict, message: "TESTING",
                                            folder_name: project_storage.managed_project_folder_path, data: "error body")
          end

          it "adds to the services errors" do
            result = service.call(storage)

            expect(result.errors.size).to eq(1)
            expect(result.errors[:create_folder])
              .to contain_exactly(I18n.t("#{error_prefix}.attributes.create_folder.conflict",
                                         folder_name: project_storage.managed_project_folder_path, parent_location: "/"))
          end

          it "interrupts the flow" do
            commands = [file_path_to_id_map, set_permissions, group_users, add_user, create_folder, remove_user,
                        rename_file]
            service.call(storage)
            expect(commands).to all(have_received(:call).at_least(:once))
          end
        end
      end
    end

    private

    def storage_error(code, data, source)
      data = StorageErrorData.new(source:, payload: data)
      StorageError.new(code:, log_message: "TESTING", data:)
    end

    def build_create_folder_result
      {
        public_storage.managed_project_folder_name =>
          ServiceResult.success(result: StorageFile.new(id: "public_id",
                                                        name: public_storage.managed_project_folder_name)),
        project_storage.managed_project_folder_name =>
          ServiceResult.success(result: StorageFile.new(id: "normal_project_id",
                                                        name: project_storage.managed_project_folder_name))
      }
    end

    def build_project_folder_permission_input
      [
        build_input_data(
          inactive_storage.project_folder_id,
          [
            { user_id: "OpenProject", permissions: OpenProject::Storages::Engine.external_file_permissions },
            { group_id: "OpenProject", permissions: [] }
          ]
        ),
        build_input_data(
          "public_id",
          [
            { user_id: "OpenProject", permissions: OpenProject::Storages::Engine.external_file_permissions },
            { user_id: "admin", permissions: OpenProject::Storages::Engine.external_file_permissions },
            { user_id: "multiple_projects_user", permissions: %i[read_files] },
            { user_id: "single_project_user", permissions: %i[read_files] },
            { group_id: "OpenProject", permissions: [] }
          ]
        ),
        build_input_data(
          "normal_project_id",
          [
            { user_id: "OpenProject", permissions: OpenProject::Storages::Engine.external_file_permissions },
            { user_id: "admin", permissions: OpenProject::Storages::Engine.external_file_permissions },
            { user_id: "multiple_projects_user", permissions: %i[read_files write_files] },
            { user_id: "single_project_user", permissions: %i[read_files write_files] },
            { group_id: "OpenProject", permissions: [] }
          ]
        ),
        build_input_data(
          renamed_storage.project_folder_id,
          [
            { user_id: "OpenProject", permissions: OpenProject::Storages::Engine.external_file_permissions },
            { user_id: "admin", permissions: OpenProject::Storages::Engine.external_file_permissions },
            { user_id: "multiple_projects_user", permissions: %i[read_files write_files] },
            { group_id: "OpenProject", permissions: [] }
          ]
        )
      ]
    end

    def build_input_data(file_id, user_permissions)
      Peripherals::StorageInteraction::Inputs::SetPermissions.build(file_id:, user_permissions:).value!
    end
  end
end
