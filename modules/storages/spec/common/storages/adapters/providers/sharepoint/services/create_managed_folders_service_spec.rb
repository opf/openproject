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

RSpec::Matchers.define_negated_matcher :not_change, :change

module Storages
  module Adapters
    module Providers
      module Sharepoint
        module Services
          RSpec.describe CreateManagedFoldersService, :disable_ssrf_filter, :webmock do
            shared_let(:admin) { create(:admin) }
            shared_let(:storage) do
              create(:sharepoint_storage, :sandbox,
                     oauth_client_token_user: admin,
                     managed_drive_id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY-uqLcDyJy5Rp1j0luD0b1v",
                     managed_drive_name: "AMPF VCR")
            end

            shared_let(:admin_remote_identity) do
              create(:remote_identity,
                     auth_source: storage.oauth_client,
                     user: admin,
                     integration: storage,
                     origin_user_id: "f220e557-9477-47d5-94a7-672843be6b0a") # Megan
            end

            shared_let(:oidc_provider) { create(:oidc_provider) }

            # USER FACTORIES
            shared_let(:oidc_user) { create(:user, authentication_provider: oidc_provider) }
            shared_let(:single_project_user) { oidc_user }
            shared_let(:single_project_user_remote_identity) do
              create(:remote_identity,
                     user: single_project_user,
                     auth_source: oidc_user.authentication_provider,
                     integration: storage,
                     origin_user_id: "a9023fd0-c421-4695-b83c-bb3ba67708d6") # OP Member
            end

            shared_let(:multiple_projects_user) { create(:user) }
            shared_let(:multiple_project_user_remote_identity) do
              create(:remote_identity,
                     user: multiple_projects_user,
                     auth_source: storage.oauth_client,
                     integration: storage,
                     origin_user_id: "49abf87c-31df-47ef-858d-fbc801b0985a") # Henrietta
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
              create(:project_storage, :with_historical_data, project_folder_mode: "automatic", storage:, project:)
            end

            shared_let(:disallowed_chars_project) do
              create(:project, name: '<=o=> | "Jedi" Project Folder ///', members: { multiple_projects_user => ordinary_role })
            end
            shared_let(:disallowed_chars_project_storage) do
              create(:project_storage, :with_historical_data, project_folder_mode: "automatic", project: disallowed_chars_project,
                                                              storage:)
            end

            shared_let(:inactive_project) do
              create(:project, name: "INACTIVE PROJECT! f0r r34lz", active: false,
                               members: { multiple_projects_user => ordinary_role })
            end
            shared_let(:inactive_project_storage) do
              create(:project_storage, :with_historical_data, project_folder_mode: "automatic", project: inactive_project,
                                                              storage:)
            end

            shared_let(:public_project) { create(:public_project, name: "PUBLIC PROJECT", active: true) }
            shared_let(:public_project_storage) do
              create(:project_storage, :with_historical_data, project_folder_mode: "automatic", project: public_project, storage:)
            end

            shared_let(:unmanaged_project) do
              create(:project, name: "Non Managed Project", active: true, members: { multiple_projects_user => ordinary_role })
            end
            shared_let(:unmanaged_project_storage) do
              create(:project_storage, :with_historical_data, project_folder_mode: "manual", project: unmanaged_project, storage:)
            end

            # This is a remote service call. We need to enable WebMock and VCR in order to record it,
            # otherwise it will run the request every test suite run.
            # Then we disable both VCR and WebMock to return to the usual state
            shared_let(:original_folder_ids) do
              use_storages_vcr_cassette("sharepoint/sync_service_original_folders") { original_folders }
            end

            subject(:service) do
              described_class.new(storage:, project_storages_scope: storage.reload.project_storages, hide_missing_folders: true)
            end

            describe "#call" do
              before { storage.update(automatically_managed: true) }
              after { delete_created_folders }

              describe "Remote Folder Creation", vcr: "sharepoint/sync_service_create_folder" do
                let(:single_project_user_origin_user_id) { single_project_user_remote_identity.origin_user_id }
                let(:multiple_project_user_origin_user_id) { multiple_project_user_remote_identity.origin_user_id }
                let(:admin_origin_user_id) { admin_remote_identity.origin_user_id }

                it "updates the project folder id for all active automatically managed projects" do
                  expect { service.call }.to change { disallowed_chars_project_storage.reload.project_folder_id }
                                               .from(nil).to(String)
                                               .and(change { project_storage.reload.project_folder_id }.from(nil).to(String))
                                               .and(change {
                                                      public_project_storage.reload.project_folder_id
                                                    }.from(nil).to(String))
                                               .and(not_change { inactive_project_storage.reload.project_folder_id })
                                               .and(not_change { unmanaged_project_storage.reload.project_folder_id })
                end

                it "adds a record to the LastProjectFolder for each new folder" do
                  skip "This introduces a bug on certain scenarios that lead to unrecoverable errors with a Sharepoint Storage"
                  scope = ->(project_storage) { LastProjectFolder.where(project_storage:).last }

                  expect { service.call }.to not_change { scope[unmanaged_project_storage].reload.origin_folder_id }
                                               .and(not_change { scope[inactive_project_storage].reload.origin_folder_id })

                  expect(scope[project_storage].origin_folder_id).to eq(project_storage.reload.project_folder_id)
                  expect(scope[public_project_storage].origin_folder_id).to eq(public_project_storage.reload.project_folder_id)
                  expect(scope[disallowed_chars_project_storage].origin_folder_id)
                    .to eq(disallowed_chars_project_storage.reload.project_folder_id)
                end

                it "creates the remote folders for all projects with automatically managed folders enabled" do
                  service.call

                  [project_storage, disallowed_chars_project_storage, public_project_storage].each do |proj_storage|
                    expect(project_folder_info(proj_storage)).to be_success
                  end
                end

                it "makes sure that the last_project_folder.origin_folder_id match the current project_folder_id" do
                  skip "This introduces a bug on certain scenarios that lead to unrecoverable errors with a Sharepoint Storage"

                  service.call

                  [project_storage, disallowed_chars_project_storage, public_project_storage].each do |proj_storage|
                    proj_storage.reload
                    the_real_last_project_folder = proj_storage.last_project_folders.last

                    expect(proj_storage.project_folder_id).to eq(the_real_last_project_folder.origin_folder_id)
                  end
                end
              end

              it "renames an already existing project folder", vcr: "sharepoint/sync_service_rename_folder" do
                original_folder = create_folder_for(disallowed_chars_project_storage, "Old Jedi Project")
                disallowed_chars_project_storage.update(project_folder_id: original_folder.id)

                service_result = service.call
                expect(service_result).to be_success
                expect(service_result.errors).to be_empty

                result = project_folder_info(disallowed_chars_project_storage).value!
                expect(result.name).to match(/_=o=_ _ _Jedi_ Project Folder ___ \(\d+\)/)
              end

              it "hides (removes all permissions) from inactive project folders", vcr: "sharepoint/sync_service_hide_inactive" do
                original_folder = create_folder_for(inactive_project_storage)
                inactive_project_storage.update(project_folder_id: original_folder.id)

                set_permissions_on(original_folder.id,
                                   [{ user_id: "f220e557-9477-47d5-94a7-672843be6b0a", permissions: [:read_files] },
                                    { user_id: "49abf87c-31df-47ef-858d-fbc801b0985a", permissions: [:write_files] },
                                    { user_id: "a9023fd0-c421-4695-b83c-bb3ba67708d6", permissions: [:write_files] }])

                expect(remote_permissions_for(inactive_project_storage))
                  .to eq({ read: ["f220e557-9477-47d5-94a7-672843be6b0a"],
                           write: %w[a9023fd0-c421-4695-b83c-bb3ba67708d6 49abf87c-31df-47ef-858d-fbc801b0985a] })

                result = service.call

                expect(result).to be_success
                expect(result.errors).to be_empty
                expect(remote_permissions_for(inactive_project_storage)).to be_empty
              end

              describe "error handling" do
                let(:error_key_prefix) { "services.errors.models.sharepoint_sync_service" }

                before { allow(Rails.logger).to receive_messages(%i[error warn]) }

                context "when reading the root folder fails" do
                  before { storage.update(managed_drive_id: "THIS-IS-NOT-A-DRIVE-ID", managed_drive_name: "Bob") }

                  it "returns a failure in case retrieving the root list fails",
                     vcr: "sharepoint/sync_service_root_read_failure" do
                    result = service.call

                    expect(result).to be_failure

                    expect(result.errors[:base])
                      .to match_array(I18n.t("#{error_key_prefix}.not_found", drive_name: storage.managed_drive_name))
                  end

                  it "logs the occurrence", vcr: "sharepoint/sync_service_root_read_failure" do
                    service.call
                    expect(Rails.logger)
                      .to have_received(:error)
                            .with(error_code: :not_found, drive_name: storage.managed_drive_name, data: String)
                  end
                end

                it "does not break in case of timeout", vcr: "sharepoint/sync_service_timeout" do
                  skip "The timeout setting isn't working as expected"
                  stub_request_with_timeout(:get, /\/root\/children$/)
                  service.call

                  expect(Rails.logger)
                    .to have_received(:error)
                          .with(command: described_class,
                                message: nil,
                                data: { body: /timed out while waiting on select/, status: nil })
                end

                context "when folder creation fails" do
                  it "doesn't update the project_storage", vcr: "sharepoint/sync_service_creation_fail" do
                    already_existing_folder = create_folder_for(project_storage)
                    result = nil

                    expect { result = service.call }.not_to change(project_storage, :project_folder_id)

                    expect(result).to be_failure
                    expect(result.errors[:create_folder])
                      .to match_array(I18n.t("#{error_key_prefix}.attributes.create_folder.conflict",
                                             folder_name: project_storage.managed_project_folder_name,
                                             parent_location: storage.managed_drive_name))
                  ensure
                    delete_folder(already_existing_folder.id)
                  end

                  it "logs the occurrence", vcr: "sharepoint/sync_service_creation_fail" do
                    already_existing_folder = create_folder_for(project_storage)
                    service.call

                    expect(Rails.logger)
                      .to have_received(:error)
                            .with(folder_name: "[Sample] Project Name _ Ehuu (#{project.id})",
                                  parent_location: storage.managed_drive_name,
                                  error_code: :conflict,
                                  data: { body: /nameAlreadyExists/, status: Integer })
                  ensure
                    delete_folder(already_existing_folder.id)
                  end
                end

                context "when folder renaming fails" do
                  it "adds an error and logs the occurrence", vcr: "sharepoint/sync_service_rename_failed" do
                    already_existing_folder = create_folder_for(project_storage)
                    original_folder = create_folder_for(project_storage, "Flawless Death Star Blueprints")
                    project_storage.update(project_folder_id: original_folder.id)

                    result = service.call

                    expect(result.errors[:rename_project_folder])
                      .to match_array(I18n.t("#{error_key_prefix}.attributes.rename_project_folder.conflict",
                                             current_path: original_folder.name,
                                             project_folder_name: project_storage.managed_project_folder_name))

                    expect(Rails.logger)
                      .to have_received(:error).with(current_path: original_folder.name,
                                                     project_folder_id: project_storage.project_folder_id,
                                                     project_folder_name: "[Sample] Project Name _ Ehuu (#{project.id})",
                                                     error_code: :conflict,
                                                     data: { body: /nameAlreadyExists/, status: Integer })
                  ensure
                    delete_folder(already_existing_folder.id)
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
                                                   storage.managed_drive_id,
                                                   "/items",
                                                   project_storage.project_folder_id.split(":").last,
                                                   "/permissions"))
                response.json(symbolize_keys: true).fetch(:value, []).each_with_object({}) do |grant, hash|
                  next if grant[:roles].member?("owner")

                  hash[grant[:roles].first.to_sym] ||= []
                  hash[grant[:roles].first.to_sym] << grant.dig(:grantedToV2, :user, :id)
                end
              end
            end

            def original_folders
              root_folder_contents.bind { return it.all_folders.map(&:id) }
            end

            def project_folder_info(project_storage)
              root_folder_contents.fmap do |storage_files|
                storage_files.files.find { |file| file.id == project_storage.project_folder_id }
              end
            end

            def root_folder_contents
              Adapters::Input::Files.build(folder: "/#{storage.managed_drive_name}").bind do |input_data|
                Adapters::Registry.resolve("sharepoint.queries.files").call(storage:, auth_strategy:, input_data:)
              end
            end

            def create_folder_for(project_storage, folder_override = nil)
              folder_name = folder_override || project_storage.managed_project_folder_name

              Adapters::Input::CreateFolder.build(folder_name:, parent_location: storage.managed_drive_id)
                                           .bind do |input_data|
                Adapters::Registry.resolve("sharepoint.commands.create_folder")
                                  .call(storage: project_storage.storage, auth_strategy:, input_data:)
                                  .value_or { fail "Folder creation failed" }
              end
            end

            def set_permissions_on(file_id, user_permissions)
              Adapters::Input::SetPermissions.build(file_id:, user_permissions:).bind do |input_data|
                Adapters::Registry.resolve("sharepoint.commands.set_permissions").call(storage:, auth_strategy:, input_data:)
              end
            end

            def delete_created_folders
              storage.project_storages.automatic.where(storage:)
                     .with_project_folder.find_each { |project_storage| delete_folder(project_storage.project_folder_id) }
            end

            def delete_folder(item_id)
              Adapters::Input::DeleteFolder.build(location: item_id).bind do |input_data|
                Adapters::Registry.resolve("sharepoint.commands.delete_folder").call(storage:, auth_strategy:, input_data:)
              end
            end

            def auth_strategy = Adapters::Registry.resolve("sharepoint.authentication.userless").call
          end
        end
      end
    end
  end
end
