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
  FakeProject = Data.define(:id, :name)

  class TestIdentifier < Adapters::Providers::Nextcloud::ManagedFolderIdentifier
    def initialize(project_storage)
      super
      @project = FakeProject.new(-273, project_storage.project.name)
    end
  end

  RSpec.describe NextcloudManagedFolderCreateService, :disable_ssrf_filter, :webmock do
    before do
      Adapters::Registry.stub("nextcloud.models.managed_folder_identifier", TestIdentifier)
    end

    after { delete_created_folders }

    describe "#call" do
      subject(:service) { described_class.new(storage:) }

      shared_let(:oidc_provider) { create(:oidc_provider) }

      shared_let(:admin) { create(:admin) }
      shared_let(:multiple_projects_user) { create(:user) }
      shared_let(:single_project_user) { create(:user) }
      shared_let(:oidc_user) { create(:user, authentication_provider: oidc_provider) }
      shared_let(:oidc_admin) { create(:admin, authentication_provider: oidc_provider) }
      shared_let(:storage) { create(:nextcloud_storage_with_local_connection, :as_automatically_managed) }

      shared_let(:remote_identities) do
        [create(:remote_identity,
                user: admin,
                auth_source: storage.oauth_client,
                integration: storage,
                origin_user_id: "admin"),
         create(:remote_identity,
                user: multiple_projects_user,
                auth_source: storage.oauth_client,
                integration: storage,
                origin_user_id: "multiple_projects_user"),
         create(:remote_identity,
                user: oidc_user,
                auth_source: oidc_provider,
                integration: storage,
                origin_user_id: "oidc_user"),
         create(:remote_identity,
                user: oidc_admin,
                auth_source: oidc_provider,
                integration: storage,
                origin_user_id: "oidc_admin"),
         create(:remote_identity,
                user: single_project_user,
                auth_source: storage.oauth_client,
                integration: storage,
                origin_user_id: "single_project_user")]
      end

      shared_let(:non_member_role) { create(:non_member, permissions: ["read_files"]) }
      shared_let(:ordinary_role) { create(:project_role, permissions: %w[read_files write_files]) }

      shared_let(:project) do
        create(:project, name: "[Sample] Project Name / Ehuu",
                         members: { multiple_projects_user => ordinary_role, single_project_user => ordinary_role })
      end
      shared_let(:project_storage) do
        create(:project_storage, :with_historical_data, project_folder_mode: "automatic", storage:, project:)
      end

      shared_let(:disallowed_chars_project) do
        create(:project, name: '<=o=> | "Jedi" Project Folder ///', members: { multiple_projects_user => ordinary_role })
      end
      shared_let(:disallowed_chars_project_storage) do
        create(:project_storage, :with_historical_data, project_folder_mode: "automatic",
                                                        project: disallowed_chars_project, storage:)
      end

      shared_let(:inactive_project) do
        create(:project, name: "INACTIVE PROJECT! f0r r34lz", active: false, members: { multiple_projects_user => ordinary_role })
      end
      shared_let(:inactive_project_storage) do
        create(:project_storage, :with_historical_data, project_folder_mode: "automatic", project: inactive_project, storage:)
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

      describe "Remote Folder Creation" do
        it "updates the project folder id for all active automatically managed projects",
           vcr: "nextcloud/managed_folder_create_service" do
          expect { service.call }.to change { disallowed_chars_project_storage.reload.project_folder_id }
                                       .from(nil).to(String)
                                       .and(change { project_storage.reload.project_folder_id }.from(nil).to(String))
                                       .and(change { public_project_storage.reload.project_folder_id }.from(nil).to(String))
                                       .and(not_change { inactive_project_storage.reload.project_folder_id })
                                       .and(not_change { unmanaged_project_storage.reload.project_folder_id })
        end

        it "adds a record to the LastProjectFolder for each new folder",
           vcr: "nextcloud/managed_folder_create_service" do
          scope = ->(project_storage) { LastProjectFolder.where(project_storage:).last }

          expect { service.call }.to not_change { scope[unmanaged_project_storage].reload.origin_folder_id }
                                       .and(not_change { scope[inactive_project_storage].reload.origin_folder_id })

          expect(scope[project_storage].origin_folder_id).to eq(project_storage.reload.project_folder_id)
          expect(scope[public_project_storage].origin_folder_id).to eq(public_project_storage.reload.project_folder_id)
          expect(scope[disallowed_chars_project_storage].origin_folder_id)
            .to eq(disallowed_chars_project_storage.reload.project_folder_id)
        end

        it "creates the remote folders for all projects with automatically managed folders enabled",
           vcr: "nextcloud/managed_folder_create_service" do
          service.call

          [project_storage, disallowed_chars_project_storage, public_project_storage].each do |proj_storage|
            expect(project_folder_info(proj_storage)).to be_success
          end
        end

        it "makes sure that the last_project_folder.origin_folder_id match the current project_folder_id",
           vcr: "nextcloud/managed_folder_create_service" do
          service.call

          [project_storage, disallowed_chars_project_storage, public_project_storage].each do |proj_storage|
            proj_storage.reload
            the_real_last_project_folder = proj_storage.last_project_folders.last

            expect(proj_storage.project_folder_id).to eq(the_real_last_project_folder.origin_folder_id)
          end
        end
      end

      it "renames an already existing project folder", vcr: "nextcloud/managed_folder_create_service_rename_folder" do
        create_folder_for(disallowed_chars_project_storage, "Old Jedi Project").bind do |original_folder|
          disallowed_chars_project_storage.update(project_folder_id: original_folder.id)
        end

        service_result = service.call
        expect(service_result).to be_success
        expect(service_result.errors).to be_empty

        result = project_folder_info(disallowed_chars_project_storage.reload).value!
        expect(result.name).to match(%r{<=o=> | "Jedi" Project Folder ||| \(-273\)})
      end

      it "hides (removes all permissions) from inactive project folders",
         vcr: "nextcloud/managed_folder_create_service_hide_inactive" do
        create_folder_for(inactive_project_storage).bind do |original_folder|
          inactive_project_storage.update(project_folder_id: original_folder.id)

          # add_users_to_group(%w[anakin leia luke])
          set_permissions_on(original_folder.id,
                             [{ user_id: "anakin", permissions: [:read_files] },
                              { user_id: "luke", permissions: [:write_files] }])
        end

        result = service.call

        expect(result).to be_success
        expect(result.errors).to be_empty
        users = remote_permissions_for(inactive_project_storage).map { |hash| hash[:user_id] }

        # Group, User
        expect(users).to contain_exactly("OpenProject", "OpenProject")
      end

      describe "error handling" do
        let(:error_prefix) { "services.errors.models.nextcloud_sync_service" }

        before { allow(Rails.logger).to receive_messages(%i[error warn]) }

        context "when the initial fetch of remote folders fails" do
          it "logs an error", vcr: "nextcloud/sync_service_root_read_failure" do
            service.call
            expect(Rails.logger)
              .to have_received(:error).with(error_code: :unauthorized,
                                             data: { body: /Server Error/, status: Integer },
                                             group_folder: storage.group_folder, username: storage.username)
          end

          it "is a failure", vcr: "nextcloud/sync_service_root_read_failure" do
            expect(service.call).to be_failure
          end

          it "adds to the services errors", vcr: "nextcloud/sync_service_root_read_failure" do
            result = service.call

            expect(result.errors.size).to eq(1)
            expect(result.errors[:base]).to contain_exactly(I18n.t("#{error_prefix}.unauthorized"))
          end
        end

        context "when we fail to set the root folder permissions" do
          let(:error) { Adapters::Results::Error.new(code: :error, source: self) }

          before do
            set_permissions_class_double = class_double(Adapters::Providers::Nextcloud::Commands::SetPermissionsCommand)
            set_permissions_double = instance_double(Adapters::Providers::Nextcloud::Commands::SetPermissionsCommand)

            allow(set_permissions_class_double).to receive(:new).with(storage).and_return(set_permissions_double)
            allow(set_permissions_double).to receive(:call).and_return(Failure(error))
            Adapters::Registry.stub("nextcloud.commands.set_permissions", set_permissions_class_double)
          end

          it "logs an error", vcr: "nextcloud/managed_folder_create_service" do
            service.call
            expect(Rails.logger).to have_received(:error)
                                      .with(error_code: :error,
                                            data: "",
                                            group: storage.group,
                                            username: storage.username)
          end

          it "is a failure", vcr: "nextcloud/managed_folder_create_service" do
            expect(service.call).to be_failure
          end

          it "adds to the services errors", vcr: "nextcloud/managed_folder_create_service" do
            result = service.call

            expect(result.errors.size).to eq(1)
            expect(result.errors[:base]).to contain_exactly(I18n.t("#{error_prefix}.error"))
          end
        end

        context "when creating folders fails" do
          it "doesn't update the project_storage", vcr: "nextcloud/sync_service_creation_fail" do
            already_existing_folder = create_folder_for(project_storage).value!
            result = nil

            expect { result = service.call }.not_to change(project_storage, :project_folder_id)

            expect(result).to be_failure
            expect(result.errors[:create_folder])
              .to match_array(I18n.t("#{error_prefix}.attributes.create_folder.conflict",
                                     folder_name: project_storage.managed_project_folder_path,
                                     parent_location: "/"))
          ensure
            delete_folder(already_existing_folder.id) if already_existing_folder
          end

          it "logs the occurrence", vcr: "nextcloud/sync_service_creation_fail" do
            already_existing_folder = create_folder_for(project_storage).value!
            service.call

            expect(Rails.logger)
              .to have_received(:error)
                    .with(folder_name: project_storage.managed_project_folder_path,
                          error_code: :conflict,
                          parent_location: "/",
                          data: { body: String, status: 405 })
          ensure
            delete_folder(already_existing_folder.id) if already_existing_folder
          end
        end
      end
    end

    private

    def set_permissions_on(file_id, user_permissions)
      Adapters::Input::SetPermissions.build(user_permissions:, file_id:).bind do |input_data|
        Adapters::Registry["nextcloud.commands.set_permissions"].call(storage:, auth_strategy:, input_data:)
      end
    end

    def remote_permissions_for(project_storage)
      Adapters::Authentication[auth_strategy].call(storage:) do |http|
        request_url = UrlBuilder.url(storage.uri, "remote.php/dav/files", storage.username,
                                     project_storage.managed_project_folder_path)
        response = http.request(:propfind, request_url, xml: permission_request_body)
        parse_acl_xml response.body.to_s
      end
    end

    def permission_request_body
      Nokogiri::XML::Builder.new do |xml|
        xml["d"].propfind(
          "xmlns:d" => "DAV:",
          "xmlns:nc" => "http://nextcloud.org/ns"
        ) do
          xml["d"].prop do
            xml["nc"].send(:"acl-list")
          end
        end
      end.to_xml
    end

    def parse_acl_xml(xml)
      found_code = "d:status[text() = 'HTTP/1.1 200 OK']"
      not_found_code = "d:status[text() = 'HTTP/1.1 404 Not Found']"
      happy_path = "/d:multistatus/d:response/d:propstat[#{found_code}]/d:prop/nc:acl-list"
      not_found_path = "/d:multistatus/d:response/d:propstat[#{not_found_code}]/d:prop"

      if Nokogiri::XML(xml).xpath(not_found_path).children.map(&:name).include?("acl-list")
        []
      else
        Nokogiri::XML(xml).xpath(happy_path).children.map do |acl|
          acl.children.each_with_object({ user_id: "", permissions: [] }) do |entry, agg|
            agg[:user_id] = entry.text if entry.name == "acl-mapping-id"
            agg[:permissions] = translate_mask_to_permissions(entry.text.to_i) if entry.name == "acl-permissions"
          end
        end
      end
    end

    def translate_mask_to_permissions(number)
      Adapters::Providers::Nextcloud::Commands::SetPermissionsCommand::PERMISSIONS_MAP
        .each_with_object([]) { |(permission, mask), list| list << permission if number & mask == mask }
    end

    def create_folder_for(project_storage, folder_override = nil)
      folder_name = folder_override || project_storage.managed_project_folder_name
      Adapters::Input::CreateFolder.build(parent_location: storage.group_folder, folder_name:).bind do |input_data|
        Adapters::Registry["nextcloud.commands.create_folder"].call(storage:, auth_strategy:, input_data:)
      end
    end

    def original_folders
      root_folder_contents.fmap do |storage_files|
        storage_files.files.find { |file| file.id == project_storage.project_folder_id }
      end
    end

    def project_folder_info(project_storage)
      root_folder_contents.fmap do |storage_files|
        storage_files.files.find { |file| file.id == project_storage.reload.project_folder_id }
      end
    end

    def root_folder_contents
      Adapters::Input::Files.build(folder: storage.group_folder).bind do |input_data|
        Adapters::Registry["nextcloud.queries.files"].call(storage:, auth_strategy:, input_data:)
      end
    end

    def delete_created_folders
      storage.project_storages.automatic
             .where(storage:)
             .where.not(project_folder_id: nil)
             .find_each { |project_storage| delete_folder(project_storage.managed_project_folder_path.chop) }
    end

    def delete_folder(item_id)
      Adapters::Input::DeleteFolder.build(location: item_id).bind do |input_data|
        Adapters::Registry["nextcloud.commands.delete_folder"].call(storage:, auth_strategy:, input_data:)
      end
    end

    def auth_strategy
      Adapters::Registry["nextcloud.authentication.userless"].call
    end
  end
end
