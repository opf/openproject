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
require "services/base_services/behaves_like_delete_service"
require_relative "shared_event_gun_examples"

RSpec.describe Storages::ProjectStorages::DeleteService, :webmock, type: :model do
  shared_examples_for "deleting project storages with project folders" do
    let(:command_double) { class_double(command_class_reference, call: ServiceResult.success) }

    before do
      Storages::Peripherals::Registry
        .stub("#{storage.short_provider_type}.commands.delete_folder", command_double)
    end

    context "if project folder mode is set to automatic" do
      let(:project_storage) do
        create(:project_storage, project:, storage:, project_folder_id: "1337", project_folder_mode: "automatic")
      end

      it "tries to remove the project folder at the remote storage" do
        expect(described_class.new(model: project_storage, user:).call).to be_success
        expect(command_double).to have_received(:call)
      end

      context "if project folder deletion request fails" do
        let(:command_double) { class_double(command_class_reference, call: ServiceResult.failure(result: 404)) }

        it "tries to remove the project folder at the remote storage and still succeed with deletion" do
          expect(described_class.new(model: project_storage, user:).call).to be_success
          expect(command_double).to have_received(:call)
        end
      end
    end

    context "if project folder mode is set to manual" do
      let(:project_storage) do
        create(:project_storage, project:, storage:, project_folder_id: "1337", project_folder_mode: "manual")
      end

      it "must not try to delete manual project folders" do
        expect(described_class.new(model: project_storage, user:).call).to be_success
        expect(command_double).not_to have_received(:call)
      end
    end
  end

  context "with records written to DB" do
    let(:user) { create(:user) }
    let(:role) { create(:project_role, permissions: [:manage_files_in_project]) }
    let(:project) { create(:project, members: { user => role }) }
    let(:other_project) { create(:project) }
    let(:storage) { create(:nextcloud_storage) }
    let(:project_storage) { create(:project_storage, project:, storage:) }
    let(:work_package) { create(:work_package, project:) }
    let(:other_work_package) { create(:work_package, project: other_project) }
    let(:file_link) { create(:file_link, container: work_package, storage:) }
    let(:other_file_link) { create(:file_link, container: other_work_package, storage:) }

    it "destroys the record" do
      project_storage
      described_class.new(model: project_storage, user:).call

      expect(Storages::ProjectStorage.where(id: project_storage.id)).not_to exist
    end

    it "deletes all FileLinks that belong to containers of the related project" do
      file_link
      other_file_link

      described_class.new(model: project_storage, user:).call

      expect(Storages::FileLink.where(id: file_link.id)).not_to exist
      expect(Storages::FileLink.where(id: other_file_link.id)).to exist
    end

    context "with Nextcloud storage" do
      let(:delete_folder_url) do
        "#{storage.host}/remote.php/dav/files/#{storage.username}/#{project_storage.project_folder_location}"
      end

      it_behaves_like "deleting project storages with project folders"
    end

    context "with OneDrive storage" do
      let(:storage) { create(:one_drive_storage) }
      let(:delete_folder_url) do
        "https://graph.microsoft.com/v1.0/drives/#{storage.drive_id}/items/#{project_storage.project_folder_location}"
      end

      it_behaves_like "deleting project storages with project folders"
    end
  end

  it_behaves_like "BaseServices delete service" do
    let(:factory) { :project_storage }
    let(:host) { model_instance.storage.host }
    let(:username) { model_instance.storage.username }
    let(:path) { model_instance.managed_project_folder_path.chop }
    let(:delete_folder_url) do
      "#{host}/remote.php/dav/files/#{username}/#{path}/"
    end

    before do
      Storages::Peripherals::Registry.stub(
        "#{model_instance.storage.short_provider_type}.commands.delete_folder",
        ->(*) { ServiceResult.success }
      )
    end

    it_behaves_like("an event gun", OpenProject::Events::PROJECT_STORAGE_DESTROYED)
  end

  private

  def command_class_reference
    if storage.provider_type_nextcloud?
      Storages::Peripherals::StorageInteraction::Nextcloud::DeleteFolderCommand
    else
      Storages::Peripherals::StorageInteraction::OneDrive::DeleteFolderCommand
    end
  end
end
