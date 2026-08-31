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

RSpec.describe Storages::ManagedFolderSyncService do
  subject(:call) { described_class.call(storage) }

  let(:storage) { create(:nextcloud_storage) }
  let(:folder_create_service) { class_double(Storages::NextcloudManagedFolderCreateService, call: ServiceResult.success) }
  let(:folder_permissions_service) do
    class_double(Storages::NextcloudManagedFolderPermissionsService, call: ServiceResult.success)
  end

  # TODO: This masks missing keys.
  #   We may need to figure out a better way to write this these tests - 2025-05-08 @mereghost
  before do
    allow(Storages::Adapters::Registry).to receive(:resolve)
      .with("nextcloud.services.upkeep_managed_folders")
      .and_return(folder_create_service)
    allow(Storages::Adapters::Registry).to receive(:resolve)
      .with("onedrive.services.upkeep_managed_folders")
      .and_return(folder_create_service)
    allow(Storages::Adapters::Registry).to receive(:resolve)
      .with("nextcloud.services.upkeep_managed_folder_permissions")
      .and_return(folder_permissions_service)
    allow(Storages::Adapters::Registry).to receive(:resolve)
      .with("onedrive.services.upkeep_managed_folder_permissions")
      .and_return(folder_permissions_service)
  end

  it { is_expected.to be_success }

  it "calls the folder create service" do
    call
    expect(folder_create_service).to have_received(:call).with(storage:)
  end

  it "calls the folder permissions service" do
    call
    expect(folder_permissions_service).to have_received(:call).with(storage:)
  end

  context "when the storage is a Nextcloud storage" do
    it "uses the Nextcloud folder create service" do
      call
      expect(Storages::Adapters::Registry).to have_received(:resolve).with("nextcloud.services.upkeep_managed_folders")
    end

    it "calls the Nextcloud folder permissions service" do
      call
      expect(Storages::Adapters::Registry)
        .to have_received(:resolve).with("nextcloud.services.upkeep_managed_folder_permissions")
    end
  end

  context "when the storage is a OneDrive storage" do
    let(:storage) { create(:onedrive_storage) }

    it "calls the OneDrive folder create service" do
      call
      expect(Storages::Adapters::Registry).to have_received(:resolve).with("onedrive.services.upkeep_managed_folders")
    end

    it "calls the OneDrive folder permissions service" do
      call
      expect(Storages::Adapters::Registry)
        .to have_received(:resolve).with("onedrive.services.upkeep_managed_folder_permissions")
    end
  end

  context "when the folder creation fails" do
    let(:folder_create_service) { class_double(Storages::NextcloudManagedFolderCreateService, call: ServiceResult.failure) }

    it { is_expected.to be_failure }

    it "calls the folder permissions service anyways" do
      call
      expect(folder_permissions_service).to have_received(:call).with(storage:)
    end
  end

  context "when the folder permissions service fails" do
    let(:folder_permissions_service) do
      class_double(Storages::NextcloudManagedFolderPermissionsService, call: ServiceResult.failure)
    end

    it { is_expected.to be_failure }
  end
end
