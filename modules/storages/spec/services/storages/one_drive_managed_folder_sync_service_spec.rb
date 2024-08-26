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

RSpec.describe Storages::OneDriveManagedFolderSyncService, :webmock do
  shared_let(:admin) { create(:admin) }

  shared_let(:storage) do
    # Automatically Managed Project Folder Drive
    create(:sharepoint_dev_drive_storage,
           drive_id: "b!dmVLG22QlE2PSW0AqVB7UOhZ8n7tjkVGkgqLNnuw2ODRDvn3haLiQIhB5UYNdqMy",
           oauth_client_token_user: admin)
  end

  # USER FACTORIES
  shared_let(:single_project_user) { create(:user) }
  shared_let(:single_project_user_token) do
    create(:remote_identity,
           user: single_project_user,
           oauth_client: storage.oauth_client,
           origin_user_id: "2ff33b8f-2843-40c1-9a17-d786bca17fba")
  end

  shared_let(:multiple_projects_user) { create(:user) }
  shared_let(:multiple_project_user_token) do
    create(:remote_identity,
           user: multiple_projects_user,
           oauth_client: storage.oauth_client,
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
           members: { multiple_projects_user => ordinary_role, single_project_user => ordinary_role })
  end
  shared_let(:project_storage) do
    create(:project_storage, :with_historical_data, project_folder_mode: "automatic", storage:, project:)
  end

  shared_let(:disallowed_chars_project) do
    create(:project, name: '<=o=> | "Jedi" Project Folder ///', members: { multiple_projects_user => ordinary_role })
  end
  shared_let(:disallowed_chars_project_storage) do
    create(:project_storage, :with_historical_data, project_folder_mode: "automatic", project: disallowed_chars_project, storage:)
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

  # This is a remote service call. We need to enable WebMock and VCR in order to record it,
  # otherwise it will run the request every test suite run.
  # Then we disable both VCR and WebMock to return to the usual state
  shared_let(:original_folder_ids) do
    use_storages_vcr_cassette("one_drive/sync_service_original_folders") do
      original_folders(storage)
    end
  end

  subject(:service) { described_class.new(storage) }

  it "responds to .call" do
    method = described_class.method(:call)

    expect(method.parameters).to contain_exactly(%i[req storage])
  end

  it "return if the storage is not automatically managed" do
    expect(described_class.call(storage)).to be_falsey
  end

  describe "#call" do
    before { storage.update(automatically_managed: true) }
    after { delete_created_folders }

    describe "Remote Folder Creation" do
      it "updates the project folder id for all active automatically managed projects",
         vcr: "one_drive/sync_service_create_folder" do
        expect { service.call }.to change { disallowed_chars_project_storage.reload.project_folder_id }
                                     .from(nil).to(String)
                                     .and(change { project_storage.reload.project_folder_id }.from(nil).to(String))
                                     .and(change { public_project_storage.reload.project_folder_id }.from(nil).to(String))
                                     .and(not_change { inactive_project_storage.reload.project_folder_id })
                                     .and(not_change { unmanaged_project_storage.reload.project_folder_id })
      end

      it "adds a record to the LastProjectFolder for each new folder",
         vcr: "one_drive/sync_service_create_folder" do
        scope = ->(project_storage) { Storages::LastProjectFolder.where(project_storage:).last }

        expect { service.call }.to not_change { scope[unmanaged_project_storage].reload.origin_folder_id }
                                     .and(not_change { scope[inactive_project_storage].reload.origin_folder_id })

        expect(scope[project_storage].origin_folder_id).to eq(project_storage.reload.project_folder_id)
        expect(scope[public_project_storage].origin_folder_id).to eq(public_project_storage.reload.project_folder_id)
        expect(scope[disallowed_chars_project_storage].origin_folder_id)
          .to eq(disallowed_chars_project_storage.reload.project_folder_id)
      end

      it "creates the remote folders for all projects with automatically managed folders enabled",
         vcr: "one_drive/sync_service_create_folder" do
        service.call

        [project_storage, disallowed_chars_project_storage, public_project_storage].each do |proj_storage|
          expect(project_folder_info(proj_storage)).to be_success
        end
      end

      it "makes sure that the last_project_folder.origin_folder_id match the current project_folder_id",
         vcr: "one_drive/sync_service_create_folder" do
        service.call

        [project_storage, disallowed_chars_project_storage, public_project_storage].each do |proj_storage|
          proj_storage.reload
          the_real_last_project_folder = proj_storage.last_project_folders.last

          expect(proj_storage.project_folder_id).to eq(the_real_last_project_folder.origin_folder_id)
        end
      end
    end

    it "renames an already existing project folder", vcr: "one_drive/sync_service_rename_folder" do
      original_folder = create_folder_for(disallowed_chars_project_storage, "Old Jedi Project")

      disallowed_chars_project_storage.update(project_folder_id: original_folder.result.id)

      service_result = service.call
      expect(service_result).to be_success
      expect(service_result.errors).to be_empty

      result = project_folder_info(disallowed_chars_project_storage).result
      expect(result.name).to match(/_=o=_ _ _Jedi_ Project Folder ___ \(\d+\)/)
    end

    it "hides (removes all permissions) from inactive project folders", vcr: "one_drive/sync_service_hide_inactive" do
      original_folder = create_folder_for(inactive_project_storage)
      inactive_project_storage.update(project_folder_id: original_folder.result.id)

      set_permissions_on(original_folder.result.id,
                         [{ user_id: "2ff33b8f-2843-40c1-9a17-d786bca17fba", permissions: [:read_files] },
                          { user_id: "248aeb72-b231-4e71-a466-67fa7df2a285", permissions: [:write_files] },
                          { user_id: "33db2c84-275d-46af-afb0-c26eb786b194", permissions: [:write_files] }])

      expect(permissions_for(inactive_project_storage))
        .to eq({ read: ["2ff33b8f-2843-40c1-9a17-d786bca17fba"],
                 write: %w[248aeb72-b231-4e71-a466-67fa7df2a285 33db2c84-275d-46af-afb0-c26eb786b194] })

      result = service.call

      expect(result).to be_success
      expect(result.errors).to be_empty
      expect(permissions_for(inactive_project_storage)).to be_empty
    end

    it "adds already logged in users to the project folder", vcr: "one_drive/sync_service_set_permissions" do
      original_folder = create_folder_for(inactive_project_storage)
      inactive_project_storage.update(project_folder_id: original_folder.result.id)

      service.call

      expect(permissions_for(project_storage))
        .to eq({ write: %w[248aeb72-b231-4e71-a466-67fa7df2a285
                           2ff33b8f-2843-40c1-9a17-d786bca17fba
                           33db2c84-275d-46af-afb0-c26eb786b194] })

      expect(permissions_for(disallowed_chars_project_storage))
        .to include({ write: %w[248aeb72-b231-4e71-a466-67fa7df2a285 33db2c84-275d-46af-afb0-c26eb786b194] })

      expect(permissions_for(inactive_project_storage)).to be_empty
    end

    it "if the project is public allows any logged in user to read the files",
       vcr: "one_drive/sync_service_public_project" do
      service.call

      expect(permissions_for(public_project_storage))
        .to eq({ read: %w[248aeb72-b231-4e71-a466-67fa7df2a285 2ff33b8f-2843-40c1-9a17-d786bca17fba],
                 write: ["33db2c84-275d-46af-afb0-c26eb786b194"] })
    end

    it "ensures that admins have full access to all folders", vcr: "one_drive/sync_service_admin_access" do
      service.call

      [project_storage, disallowed_chars_project_storage, public_project_storage].each do |ps|
        expect(permissions_for(ps)[:write]).to include("33db2c84-275d-46af-afb0-c26eb786b194")
      end
    end

    describe "error handling" do
      let(:error_key_prefix) { "services.errors.models.one_drive_sync_service" }

      before { allow(Rails.logger).to receive_messages(%i[error warn]) }

      context "when reading the root folder fails" do
        before { storage.update(drive_id: "THIS-IS-NOT-A-DRIVE-ID") }

        it "returns a failure in case retrieving the root list fails", vcr: "one_drive/sync_service_root_read_failure" do
          result = service.call

          expect(result).to be_failure
          expect(result.errors[:remote_folders])
            .to match_array(I18n.t("#{error_key_prefix}.attributes.remote_folders.request_error", drive_id: storage.drive_id))
        end

        it "logs the occurrence", vcr: "one_drive/sync_service_root_read_failure" do
          service.call

          expect(Rails.logger)
            .to have_received(:error)
                  .with(error_code: :request_error, drive_id: storage.drive_id, message: nil, data: /drive id/)
        end
      end

      it "does not break in case of timeout", vcr: "one_drive/sync_service_timeout" do
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
        it "doesn't update the project_storage", vcr: "one_drive/sync_service_creation_fail" do
          already_existing_folder = create_folder_for(project_storage).result
          result = nil

          expect { result = service.call }.not_to change(project_storage, :project_folder_id)

          expect(result).to be_success
          expect(result.errors[:create_folder])
            .to match_array(I18n.t("#{error_key_prefix}.attributes.create_folder.conflict",
                                   folder_name: project_storage.managed_project_folder_path, parent_location: "/"))
        ensure
          delete_folder(already_existing_folder.id)
        end

        it "logs the occurrence", vcr: "one_drive/sync_service_creation_fail" do
          already_existing_folder = create_folder_for(project_storage).result
          service.call

          expect(Rails.logger)
            .to have_received(:error)
                  .with(folder_name: "[Sample] Project Name _ Ehuu (#{project.id})",
                        error_code: :conflict,
                        message: nil,
                        data: /nameAlreadyExists/)
        ensure
          delete_folder(already_existing_folder.id)
        end
      end

      context "when folder renaming fails" do
        it "adds an error and logs the occurrence", vcr: "one_drive/sync_service_rename_failed" do
          already_existing_folder = create_folder_for(project_storage)
          original_folder = create_folder_for(project_storage, "Flawless Death Star Blueprints")
          project_storage.update(project_folder_id: original_folder.result.id)

          result = service.call

          expect(result.errors[:rename_project_folder])
            .to match_array(I18n.t("#{error_key_prefix}.attributes.rename_project_folder.conflict",
                                   current_path: original_folder.result.name,
                                   project_folder_name: project_storage.managed_project_folder_path))

          expect(Rails.logger)
            .to have_received(:error).with(folder_id: project_storage.project_folder_id,
                                           folder_name: "[Sample] Project Name _ Ehuu (#{project.id})",
                                           error_code: :conflict,
                                           message: nil,
                                           data: /nameAlreadyExists/)
        ensure
          delete_folder(already_existing_folder.result.id)
        end
      end

      context "when setting permission fails" do
        it "logs the occurrence", vcr: "one_drive/sync_service_fail_add_user" do
          single_project_user_token.update(origin_user_id: "my_name_is_mud")

          service.call
          expect(Rails.logger)
            .to have_received(:error)
                  .with(error_code: :bad_request,
                        message: nil,
                        data: /noResolvedUsers/).twice
        end
      end
    end
  end

  private

  def permissions_for(project_storage)
    return if project_folder_info(project_storage).failure?

    Storages::Peripherals::StorageInteraction::Authentication[auth_strategy].call(storage:) do |http|
      response = http.get(Storages::UrlBuilder.url(storage.uri,
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
    root_folder_contents
      .on_success { |result| return result.result.files.select(&:folder?).map(&:id) }
  end

  def project_folder_info(project_storage)
    root_folder_contents.map do |storage_files|
      storage_files.files.find { |file| file.id == project_storage.project_folder_id }
    end
  end

  def root_folder_contents
    Storages::Peripherals::Registry.resolve("one_drive.queries.files")
                                   .call(storage:, auth_strategy:, folder: Storages::Peripherals::ParentFolder.new("/"))
  end

  def create_folder_for(project_storage, folder_override = nil)
    folder_name = folder_override || project_storage.managed_project_folder_path
    parent_location = Storages::Peripherals::ParentFolder.new("/")

    Storages::Peripherals::Registry.resolve("one_drive.commands.create_folder")
                                   .call(storage: project_storage.storage,
                                         auth_strategy:,
                                         folder_name:,
                                         parent_location:)
  end

  def set_permissions_on(file_id, user_permissions)
    input_data = Storages::Peripherals::StorageInteraction::Inputs::SetPermissions
                   .build(file_id:, user_permissions:)
                   .value!
    Storages::Peripherals::Registry.resolve("one_drive.commands.set_permissions")
                                   .call(storage:, auth_strategy:, input_data:)
                                   .on_failure { p _1.inspect }
  end

  def delete_created_folders
    storage.project_storages.automatic
           .where(storage:)
           .where.not(project_folder_id: nil)
           .find_each { |project_storage| delete_folder(project_storage.project_folder_id) }
  end

  def delete_folder(item_id)
    Storages::Peripherals::Registry.resolve("one_drive.commands.delete_folder")
                                   .call(storage:, auth_strategy:, location: item_id)
  end

  def auth_strategy
    Storages::Peripherals::Registry.resolve("one_drive.authentication.userless").call
  end
end
