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
          RSpec.describe SetPermissionsOnManagedFoldersService, :disable_ssrf_filter, :webmock do
            shared_let(:admin) { create(:admin) }
            shared_let(:storage) do
              # Automatically Managed Project Folder Drive
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
            shared_let(:oidc_user) { create(:user, identity_url: "#{oidc_provider.slug}:qweqweqweqwe") }

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
                                oidc_user => read_only_role,
                                single_project_user => ordinary_role })
            end
            shared_let(:project_storage) do
              create :project_storage, :with_historical_data, project_folder_mode: "automatic",
                                                              storage:,
                                                              project:
            end

            shared_let(:disallowed_chars_project) do
              create(:project, name: '<=o=> | "Jedi" Project Folder ///', members: { multiple_projects_user => ordinary_role })
            end
            shared_let(:disallowed_chars_project_storage) do
              create :project_storage, :with_historical_data, project_folder_mode: "automatic",
                                                              project: disallowed_chars_project,
                                                              storage:
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
              create :project_storage, :with_historical_data, project_folder_mode: "automatic",
                                                              project: public_project,
                                                              storage:
            end

            shared_let(:unmanaged_project) do
              create(:project, name: "Non Managed Project", active: true, members: { multiple_projects_user => ordinary_role })
            end
            shared_let(:unmanaged_project_storage) do
              create :project_storage, :with_historical_data, project_folder_mode: "manual",
                                                              project: unmanaged_project,
                                                              storage:
            end

            # This is a remote service call. We need to enable WebMock and VCR in order to record it,
            # otherwise it will run the request every test suite run.
            # Then we disable both VCR and WebMock to return to the usual state
            shared_let(:original_folder_ids) do
              use_storages_vcr_cassette("sharepoint/sync_service_original_folders") do
                original_folders(storage)
              end
            end

            subject(:service) { described_class.new(storage:) }

            describe "#call" do
              before do
                storage.update(automatically_managed: true)
                CreateManagedFoldersService.call(storage:)
              end

              after { delete_created_folders }

              it "sets permissions for project's (private with 3 members) folder according to member's roles",
                 vcr: "sharepoint/set_permissions_service_multi_user_project" do
                service.call

                expect(remote_permissions_for(project_storage))
                  .to eq({ write: [admin_remote_identity.origin_user_id,
                                   single_project_user_remote_identity.origin_user_id,
                                   multiple_project_user_remote_identity.origin_user_id] })
              end

              it "sets permissions for project's (private with 1 members) folder according to member's roles",
                 vcr: "sharepoint/set_permissions_service_single_user_project" do
                service.call

                expect(remote_permissions_for(disallowed_chars_project_storage))
                  .to eq({ write: [admin_remote_identity.origin_user_id,
                                   multiple_project_user_remote_identity.origin_user_id] })
              end

              it "on public projects allow read access for all users and write to admins",
                 vcr: "sharepoint/set_permissions_service_public_project" do
                service.call

                expect(remote_permissions_for(public_project_storage))
                  .to eq({ write: [admin_remote_identity.origin_user_id],
                           read: [single_project_user_remote_identity.origin_user_id,
                                  multiple_project_user_remote_identity.origin_user_id] })
              end

              context "when passing a project storages scope" do
                subject(:service) { described_class.new(storage:, project_storages_scope:) }

                let(:project_storages_scope) { ProjectStorage.where(id: [project_storage.id, unmanaged_project_storage.id]) }

                it "sets permissions for the active managed project storages in scope",
                   vcr: "sharepoint/set_permissions_service_project_storage_scoped" do
                  service.call

                  expect(remote_permissions_for(project_storage)).not_to be_empty
                  expect(remote_permissions_for(public_project_storage)).to be_empty
                end
              end

              context "when the user is an admin", vcr: "sharepoint/set_permissions_service_admin_all_access" do
                it "ensures they have full access to all folders" do
                  service.call

                  [project_storage, disallowed_chars_project_storage, public_project_storage].each do |ps|
                    expect(remote_permissions_for(ps)[:write]).to include(admin_remote_identity.origin_user_id)
                  end
                end
              end

              describe "error handling" do
                let(:error_key_prefix) { "services.errors.models.one_drive_sync_service" }

                before { allow(Rails.logger).to receive_messages(%i[error warn]) }

                context "when setting permission fails" do
                  it "logs the occurrence", vcr: "sharepoint/set_permissions_service_invalid_user" do
                    single_project_user_remote_identity.update(origin_user_id: "my_name_is_mud")

                    service.call
                    expect(Rails.logger)
                      .to have_received(:error)
                            .with(error_code: :bad_request,
                                  data: { body: /One or more users could/, status: Integer }).twice
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

            def original_folders(_storage)
              root_folder_contents.fmap { it.all_folders.map(&:id) }
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
