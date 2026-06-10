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
  RSpec.describe OneDriveManagedFolderPermissionsService, :disable_ssrf_filter, :webmock do
    shared_let(:admin) { create(:admin) }
    shared_let(:storage) do
      # Automatically Managed Project Folder Drive
      create(:one_drive_sandbox_storage,
             drive_id: "b!dmVLG22QlE2PSW0AqVB7UOhZ8n7tjkVGkgqLNnuw2ODRDvn3haLiQIhB5UYNdqMy",
             oauth_client_token_user: admin)
    end
    shared_let(:admin_remote_identity) do
      create(:remote_identity,
             auth_source: storage.oauth_client,
             user: admin,
             integration: storage,
             origin_user_id: "33db2c84-275d-46af-afb0-c26eb786b194")
    end

    shared_let(:oidc_provider) { create(:oidc_provider) }

    # USER FACTORIES
    shared_let(:oidc_user) do
      identity_url = "#{oidc_provider.slug}:qweqweqweqwe"
      create(:user, identity_url:)
    end
    shared_let(:single_project_user) { oidc_user }
    shared_let(:single_project_user_remote_identity) do
      create(:remote_identity,
             user: single_project_user,
             auth_source: oidc_user.authentication_provider,
             integration: storage,
             origin_user_id: "2ff33b8f-2843-40c1-9a17-d786bca17fba")
    end

    shared_let(:multiple_projects_user) { create(:user) }
    shared_let(:multiple_project_user_remote_identity) do
      create(:remote_identity,
             user: multiple_projects_user,
             auth_source: storage.oauth_client,
             integration: storage,
             origin_user_id: "248aeb72-b231-4e71-a466-67fa7df2a285")
    end

    # ROLE FACTORIES
    shared_let(:ordinary_role) { create(:project_role, permissions: %w[read_files write_files]) }
    shared_let(:read_only_role) { create(:project_role, permissions: %w[read_files]) }
    shared_let(:non_member_role) { create(:non_member, permissions: %w[read_files]) }

    # PROJECT FACTORIES
    shared_let(:project) do
      create(:project,
             name: "[Sample] Project Name / Ehuu",
             members: { multiple_projects_user => ordinary_role,
                        oidc_user => ordinary_role,
                        single_project_user => ordinary_role })
    end
    shared_let(:project_storage) do
      create :project_storage, :with_historical_data, project_folder_mode: "automatic",
                                                      storage:,
                                                      project:,
                                                      project_folder_id: "01AZJL5PKF6CYXWCIXVNDIF6RXTCRH5OOK"
    end

    shared_let(:disallowed_chars_project) do
      create(:project, name: '<=o=> | "Jedi" Project Folder ///', members: { multiple_projects_user => ordinary_role })
    end
    shared_let(:disallowed_chars_project_storage) do
      create :project_storage, :with_historical_data, project_folder_mode: "automatic",
                                                      project: disallowed_chars_project,
                                                      storage:,
                                                      project_folder_id: "01AZJL5PKVY6USXYVCNJFINFV32VEZRP4K"
    end

    shared_let(:inactive_project) do
      create(:project, name: "INACTIVE PROJECT! f0r r34lz", active: false, members: { multiple_projects_user => ordinary_role })
    end
    shared_let(:inactive_project_storage) do
      create(:project_storage, :with_historical_data, project_folder_mode: "automatic", project: inactive_project, storage:)
    end

    shared_let(:public_project) { create(:public_project, name: "PUBLIC PROJECT", active: true) }
    shared_let(:public_project_storage) do
      create :project_storage, :with_historical_data, project_folder_mode: "automatic",
                                                      project: public_project,
                                                      storage:,
                                                      project_folder_id: "01AZJL5PI473R5DL4W4BB3SLISDSVFFDXZ"
    end

    shared_let(:unmanaged_project) do
      create(:project, name: "Non Managed Project", active: true, members: { multiple_projects_user => ordinary_role })
    end
    shared_let(:unmanaged_project_storage) do
      create :project_storage, :with_historical_data, project_folder_mode: "manual",
                                                      project: unmanaged_project,
                                                      storage:,
                                                      project_folder_id: "SHOULD-NOT-BE-REQUESTED"
    end

    # This is a remote service call. We need to enable WebMock and VCR in order to record it,
    # otherwise it will run the request every test suite run.
    # Then we disable both VCR and WebMock to return to the usual state
    shared_let(:original_folder_ids) do
      use_storages_vcr_cassette("one_drive/sync_service_original_folders") do
        original_folders(storage)
      end
    end

    subject(:service) { described_class.new(storage:) }

    describe "#call" do
      before { storage.update(automatically_managed: true) }
      after { delete_created_folders }

      context "when folder were newly created", vcr: "one_drive/sync_service_create_folder" do
        let(:set_permissions) { Adapters::Providers::OneDrive::Commands::SetPermissionsCommand }
        let(:single_project_user_origin_user_id) { single_project_user_remote_identity.origin_user_id }
        let(:multiple_project_user_origin_user_id) { multiple_project_user_remote_identity.origin_user_id }
        let(:admin_origin_user_id) { admin_remote_identity.origin_user_id }

        before { allow(set_permissions).to receive(:call).and_call_original }

        it "sets permissions for folders exactly 3 times" do
          service.call

          expect(set_permissions).to have_received(:call).with(
            auth_strategy:,
            input_data: an_instance_of(Adapters::Input::SetPermissions),
            storage: an_instance_of(OneDriveStorage)
          ).exactly(3).times
        end

        it "sets permissions for project's (private with 3 members) folder according to member's roles" do
          service.call

          expect(set_permissions).to have_received(:call).with(
            auth_strategy:,
            input_data: having_attributes(
              file_id: project_storage.project_folder_id,
              user_permissions:
                [{ user_id: admin_origin_user_id, permissions: [:write_files] },
                 { user_id: single_project_user_origin_user_id, permissions: [:write_files] },
                 { user_id: multiple_project_user_origin_user_id, permissions: [:write_files] }]
            ),
            storage: an_instance_of(OneDriveStorage)
          ).once
        end

        it "sets permissions for project's (private with 1 members) folder according to member's roles" do
          service.call

          expect(set_permissions).to have_received(:call).with(
            auth_strategy:,
            input_data: having_attributes(
              file_id: disallowed_chars_project_storage.project_folder_id,
              user_permissions:
                [
                  # admin(not a member of the project) receives write access as expected
                  { user_id: admin_origin_user_id, permissions: [:write_files] },
                  { user_id: multiple_project_user_origin_user_id, permissions: [:write_files] }
                ]
            ),
            storage: an_instance_of(OneDriveStorage)
          ).once
        end

        it "sets permissions for project's (public with 0 members) folder appropriately" do
          service.call

          expect(set_permissions).to have_received(:call).with(
            auth_strategy:,
            input_data: having_attributes(
              file_id: public_project_storage.project_folder_id,
              user_permissions:
                [
                  # admin gets write access
                  { user_id: admin_origin_user_id, permissions: [:write_files] },
                  # other non members get read access
                  { user_id: single_project_user_origin_user_id, permissions: [:read_files] },
                  { user_id: multiple_project_user_origin_user_id, permissions: [:read_files] }
                ]
            ),
            storage: an_instance_of(OneDriveStorage)
          ).once
        end

        context "when passing a project storages scope" do
          subject(:service) { described_class.new(storage:, project_storages_scope:) }

          let(:project_storages_scope) { ProjectStorage.where(id: [project_storage.id, unmanaged_project_storage.id]) }

          it "sets permissions for the active project storage in scope" do
            service.call

            expect(set_permissions).to have_received(:call).once
            expect(set_permissions).to have_received(:call).with(
              auth_strategy: anything,
              storage: anything,
              input_data: having_attributes(file_id: project_storage.project_folder_id)
            ).once
          end

          it "ignores the unmanaged project storage in scope" do
            service.call

            expect(set_permissions).not_to have_received(:call).with(
              auth_strategy: anything,
              storage: anything,
              input_data: having_attributes(file_id: unmanaged_project_storage.project_folder_id)
            )
          end

          it "ignores a managed project storage outside the scope" do
            service.call

            expect(set_permissions).not_to have_received(:call).with(
              auth_strategy: anything,
              storage: anything,
              input_data: having_attributes(file_id: public_project_storage.project_folder_id)
            )
          end
        end
      end

      context "when users are already logged in", vcr: "one_drive/sync_service_set_permissions" do
        before do
          # ensuring the project_folder_ids match the cassette
          project_storage.update!(project_folder_id: "01AZJL5PLIGSIHNQX7VVHJQHXH6WGXTKZQ")
          disallowed_chars_project_storage.update!(project_folder_id: "01AZJL5PMLKINPNTC5JZFLF2RNI5QODOOK")
          public_project_storage.update!(project_folder_id: "01AZJL5PK3YKOMDXIHRRDLAXFU5BJ4KLXY")
          inactive_project_storage.update!(project_folder_id: "01AZJL5PK24YOPXISOHVF3A56DI2EATQC5")
        end

        it "adds them to the project folder" do
          original_folder = create_folder_for(inactive_project_storage)
          inactive_project_storage.update(project_folder_id: original_folder.id)

          service.call

          expect(remote_permissions_for(project_storage))
            .to eq({ write: %w[248aeb72-b231-4e71-a466-67fa7df2a285
                               2ff33b8f-2843-40c1-9a17-d786bca17fba
                               33db2c84-275d-46af-afb0-c26eb786b194] })

          expect(remote_permissions_for(disallowed_chars_project_storage))
            .to include({ write: %w[248aeb72-b231-4e71-a466-67fa7df2a285 33db2c84-275d-46af-afb0-c26eb786b194] })

          expect(remote_permissions_for(inactive_project_storage)).to be_empty
        end

        context "and when two project storages have the same project_folder_id (regression #75022)" do
          before do
            create(:project_storage, storage:, project_folder_id: project_storage.project_folder_id)
          end

          it "fails with an appropriate error", vcr: "one_drive/sync_service_set_permissions" do
            result = service.call
            expect(result).to be_failure
            expect(result.errors.details[:set_folder_permission]).to contain_exactly(
              error: :folder_id_collision,
              folder: project_storage.project_folder_id
            )

            # Ensure presence of a translation
            expect(result.errors.full_messages).to all(be_a(String))
          end
        end
      end

      context "when the project is public", vcr: "one_drive/sync_service_public_project" do
        before do
          # ensuring the project_folder_ids match the cassette
          project_storage.update!(project_folder_id: "01AZJL5PLBQEL7TBIV5FD2HOAR4LSCH3HF")
          disallowed_chars_project_storage.update!(project_folder_id: "01AZJL5PLTTFRO3FI2SNCK7AL6JV6CPSB6")
          public_project_storage.update!(project_folder_id: "01AZJL5PIISB6WZDU6AVCLDNEGCY22UULI")
        end

        it "allows any logged in user to read the files" do
          service.call

          expect(remote_permissions_for(public_project_storage))
            .to eq({ read: %w[248aeb72-b231-4e71-a466-67fa7df2a285 2ff33b8f-2843-40c1-9a17-d786bca17fba],
                     write: ["33db2c84-275d-46af-afb0-c26eb786b194"] })
        end
      end

      context "when the user is an admin", vcr: "one_drive/sync_service_admin_access" do
        before do
          # ensuring the project_folder_ids match the cassette
          project_storage.update!(project_folder_id: "01AZJL5PN33BSGWNSWKRHYXH74YI4QLSDH")
          disallowed_chars_project_storage.update!(project_folder_id: "01AZJL5PIXSSWKBU73FFGKZN6LXAULGDXO")
          public_project_storage.update!(project_folder_id: "01AZJL5PMDPQHEYW65ENB26FQNWK73Y7NU")
        end

        it "ensures they have full access to all folders" do
          service.call

          [project_storage, disallowed_chars_project_storage, public_project_storage].each do |ps|
            expect(remote_permissions_for(ps)[:write]).to include("33db2c84-275d-46af-afb0-c26eb786b194")
          end
        end
      end

      describe "error handling" do
        let(:error_key_prefix) { "services.errors.models.one_drive_sync_service" }

        before { allow(Rails.logger).to receive_messages(%i[error warn]) }

        context "when setting permission fails" do
          before do
            # ensuring the project_folder_ids match the cassette
            project_storage.update!(project_folder_id: "01AZJL5POLGVTUAI3545DJ6CN24YVYIGMV")
            disallowed_chars_project_storage.update!(project_folder_id: "01AZJL5PNQGJLKUIKERBFKYNTB732KYF3V")
            public_project_storage.update!(project_folder_id: "01AZJL5PIYDDYS33Z4T5E2GODLZ2ABLOFV")
          end

          it "logs the occurrence", vcr: "one_drive/sync_service_fail_add_user" do
            single_project_user_remote_identity.update(origin_user_id: "my_name_is_mud")

            service.call
            expect(Rails.logger)
              .to have_received(:error)
                    .with(error_code: :bad_request,
                          data: { body: /noResolvedUsers/, status: Integer }).twice
          end
        end
      end
    end

    private

    def remote_permissions_for(project_storage)
      return if project_folder_info(project_storage).failure?

      Adapters::Authentication[auth_strategy].call(storage:) do |http|
        response = http.get(UrlBuilder.url(storage.uri,
                                           "/v1.0/drives",
                                           storage.drive_id,
                                           "/items",
                                           project_storage.project_folder_id,
                                           "/permissions"))
        response.json(symbolize_keys: true).fetch(:value, []).each_with_object({}) do |grant, hash|
          next if grant[:roles].member?("owner")

          hash[grant[:roles].first.to_sym] ||= []
          hash[grant[:roles].first.to_sym] << grant.dig(:grantedToV2, :user, :id)
        end
      end
    end

    def original_folders(_storage)
      root_folder_contents.fmap { it.all_folders.map(&:id) }
    end

    def project_folder_info(project_storage)
      root_folder_contents.fmap do |storage_files|
        storage_files.files.find { |file| file.id == project_storage.project_folder_id }
      end
    end

    def root_folder_contents
      Adapters::Input::Files.build(folder: "/").bind do |input_data|
        Adapters::Registry.resolve("one_drive.queries.files").call(storage:, auth_strategy:, input_data:)
      end
    end

    def create_folder_for(project_storage, folder_override = nil)
      folder_name = folder_override || project_storage.managed_project_folder_path

      Adapters::Input::CreateFolder.build(folder_name:, parent_location: "/").bind do |input_data|
        Adapters::Registry.resolve("one_drive.commands.create_folder")
                          .call(storage: project_storage.storage, auth_strategy:, input_data:)
                          .value_or { fail it.inspect }
      end
    end

    def set_permissions_on(file_id, user_permissions)
      Adapters::Input::SetPermissions.build(file_id:, user_permissions:).bind do |input_data|
        Adapters::Registry.resolve("one_drive.commands.set_permissions")
                          .call(storage:, auth_strategy:, input_data:)
                          .value_or { fail it.inspect }
      end
    end

    def delete_created_folders
      storage.project_storages.automatic
             .where(storage:)
             .with_project_folder
             .find_each { |project_storage| delete_folder(project_storage.project_folder_id) }
    end

    def delete_folder(item_id)
      Adapters::Input::DeleteFolder.build(location: item_id).bind do |input_data|
        Adapters::Registry.resolve("one_drive.commands.delete_folder").call(storage:, auth_strategy:, input_data:)
      end
    end

    def auth_strategy = Adapters::Registry.resolve("one_drive.authentication.userless").call
  end
end
