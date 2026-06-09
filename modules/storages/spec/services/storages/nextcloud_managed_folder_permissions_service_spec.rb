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

  RSpec.describe NextcloudManagedFolderPermissionsService, :disable_ssrf_filter, :webmock do
    shared_let(:oidc_provider) { create(:oidc_provider) }

    shared_let(:admin) { create(:admin) }
    shared_let(:multiple_projects_user) { create(:user) }
    shared_let(:single_project_user) { create(:user, authentication_provider: oidc_provider) }
    shared_let(:oidc_admin) { create(:admin, authentication_provider: oidc_provider) }
    shared_let(:storage) { create(:nextcloud_storage_with_local_connection, :as_automatically_managed) }

    shared_let(:remote_identities) do
      [create(:remote_identity,
              user: admin,
              auth_source: storage.oauth_client,
              integration: storage,
              origin_user_id: "anakin"),
       create(:remote_identity,
              user: multiple_projects_user,
              auth_source: storage.oauth_client,
              integration: storage,
              origin_user_id: "leia"),
       create(:remote_identity,
              user: single_project_user,
              auth_source: oidc_provider,
              integration: storage,
              origin_user_id: "luke")]
    end

    subject(:service) { described_class.new(storage:) }

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
      create(:project_storage, :with_historical_data,
             project_folder_mode: "automatic", project: disallowed_chars_project, storage:)
    end

    shared_let(:inactive_project) do
      create(:project, name: "INACTIVE PROJECT! f0r r34lz", active: false,
                       members: { multiple_projects_user => ordinary_role })
    end
    shared_let(:inactive_project_storage) do
      create(:project_storage, :with_historical_data, project_folder_mode: "automatic", project: inactive_project, storage:)
    end

    shared_let(:public_project) { create(:public_project, name: "PUBLIC PROJECT", active: true) }
    shared_let(:public_project_storage) do
      create(:project_storage, :with_historical_data, project_folder_mode: "automatic", project: public_project, storage:)
    end

    before do
      Adapters::Registry.stub("nextcloud.models.managed_folder_identifier", TestIdentifier)
      setup_remote_folders
    end

    after { delete_remote_folders }

    describe "#call" do
      it "adds already logged in users to the project folder", vcr: "nextcloud/managed_folder_set_permissions" do
        expect(service.call).to be_success

        # Group, user1, user2...
        expect(remote_permissions_for(project_storage)).to contain_exactly(
          { user_id: "OpenProject", permissions: [] },
          { user_id: "OpenProject", permissions: described_class::FILE_PERMISSIONS },
          { user_id: "anakin", permissions: described_class::FILE_PERMISSIONS },
          { user_id: "luke", permissions: %i[read_files write_files] },
          { user_id: "leia", permissions: %i[read_files write_files] }
        )

        expect(remote_permissions_for(disallowed_chars_project_storage)).to contain_exactly(
          { user_id: "OpenProject", permissions: [] },
          { user_id: "OpenProject",
            permissions: described_class::FILE_PERMISSIONS },
          { user_id: "anakin",
            permissions: described_class::FILE_PERMISSIONS },
          { user_id: "leia",
            permissions: %i[read_files write_files] }
        )

        expect(remote_permissions_for(inactive_project_storage)).to be_empty
      end

      it "if the project is public allows any logged in user to read the files",
         vcr: "nextcloud/managed_folder_set_permissions_public" do
        service.call

        expect(remote_permissions_for(public_project_storage)).to contain_exactly(
          { user_id: "OpenProject", permissions: [] },
          { user_id: "OpenProject",
            permissions: described_class::FILE_PERMISSIONS },
          { user_id: "anakin",
            permissions: described_class::FILE_PERMISSIONS },
          { user_id: "admin", permissions: [:read_files] },
          { user_id: "luke", permissions: [:read_files] },
          { user_id: "leia", permissions: [:read_files] }
        )
      end

      it "ensures that admins have full access to all folders", vcr: "nextcloud/managed_folder_set_permissions_admin_access" do
        service.call

        [project_storage, disallowed_chars_project_storage, public_project_storage].each do |ps|
          expect(remote_permissions_for(ps))
            .to include({ user_id: "anakin", permissions: %i[read_files write_files create_files delete_files share_files] })
        end
      end

      it "adds and removes users from the remote group", vcr: "nextcloud/managed_folder_set_permissions_group_users" do
        service.call

        users = Adapters::Input::GroupUsers.build(group: storage.group).bind do |input_data|
          Adapters::Registry["nextcloud.queries.group_users"].call(storage:, auth_strategy:, input_data:).value!
        end

        expect(users).to match_array(%w[OpenProject anakin luke leia admin])
      ensure
        %w[anakin luke leia].each do |user|
          Adapters::Input::RemoveUserFromGroup.build(group: storage.group, user:).bind do |input_data|
            Adapters::Registry["nextcloud.commands.remove_user_from_group"].call(storage:, auth_strategy:, input_data:)
          end
        end
      end

      context "when two project storages have the same project_folder_id (regression #75022)" do
        before do
          create(:project_storage, storage:, project_folder_id: project_storage.project_folder_id)
        end

        it "fails with an appropriate error", vcr: "nextcloud/managed_folder_set_permissions" do
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

    private

    def setup_remote_folders
      storage.project_storages.each do |project_storage|
        Adapters::Input::CreateFolder
          .build(folder_name: project_storage.managed_project_folder_path, parent_location: "/").bind do |input_data|
          Adapters::Registry["nextcloud.commands.create_folder"]
            .call(storage:, auth_strategy:, input_data:)
            .bind { project_storage.update(project_folder_id: it.id) }
        end
      end
    end

    def delete_remote_folders
      storage.project_storages.each do |project_storage|
        Adapters::Input::DeleteFolder.build(location: project_storage.managed_project_folder_path).bind do |input_data|
          Adapters::Registry["nextcloud.commands.delete_folder"].call(storage:, auth_strategy:, input_data:)
        end
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

    def set_permissions_on(file_id, user_permissions)
      Adapters::Input::SetPermissions.build(user_permissions:, file_id:).bind do |input_data|
        Adapters::Registry["nextcloud.commands.set_permissions"].call(storage:, auth_strategy:, input_data:)
      end
    end

    def create_folder_for(project_storage, folder_override = nil)
      folder_name = folder_override || project_storage.managed_project_folder_name
      Adapters::Input::CreateFolder.build(parent_location: storage.group_folder, folder_name:).bind do |input_data|
        Adapters::Registry["nextcloud.commands.create_folder"].call(storage:, auth_strategy:, input_data:)
      end
    end

    def auth_strategy = Adapters::Registry["nextcloud.authentication.userless"].call
  end
end
