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

RSpec.describe OpenProject::Events do
  def fire_event(event_constant_name)
    OpenProject::Notifications.send(
      "#{described_class}::#{event_constant_name}".constantize,
      payload
    )
  end

  before do
    allow(Storages::ManageStorageIntegrationsJob).to receive(:debounce)
    allow(Storages::AutomaticallyManagedStorageSyncJob).to receive(:debounce)
  end

  %w[
    PROJECT_STORAGE_CREATED
    PROJECT_STORAGE_UPDATED
    PROJECT_STORAGE_DESTROYED
  ].each do |event|
    describe(event) do
      subject { fire_event(event) }

      context "when payload is empty" do
        let(:payload) { {} }

        it do
          subject
          expect(Storages::AutomaticallyManagedStorageSyncJob).not_to have_received(:debounce)
        end
      end

      context "when payload contains automatic project_folder_mode" do
        let(:payload) { { project_folder_mode: "automatic", storage: create(:nextcloud_storage) } }

        it do
          subject
          expect(Storages::AutomaticallyManagedStorageSyncJob).to have_received(:debounce).with(payload[:storage])
        end

        it do
          allow(Storages::ManageStorageIntegrationsJob).to receive(:disable_cron_job_if_needed)
          subject
          expect(Storages::ManageStorageIntegrationsJob).to have_received(:disable_cron_job_if_needed)
        end
      end
    end
  end

  %w[
    MEMBER_CREATED
    MEMBER_UPDATED
    MEMBER_DESTROYED
  ].each do |event|
    describe(event) do
      let(:project_role) { create(:existing_project_role) }
      let(:project_storage) { create(:project_storage) }
      let(:member) { create(:work_package_member, roles: [project_role], project: project_storage.project) }

      let(:payload) { { member: } }

      subject { fire_event(event) }

      it do
        subject
        expect(Storages::AutomaticallyManagedStorageSyncJob).to have_received(:debounce).with(project_storage.storage)
      end
    end
  end

  %w[PROJECT_UPDATED
     PROJECT_RENAMED
     PROJECT_ARCHIVED
     PROJECT_UNARCHIVED].each do |event|
    describe(event) do
      let(:project_storage) { create(:project_storage, :as_automatically_managed) }
      let(:payload) { { project: project_storage.project } }

      subject { fire_event(event) }

      it do
        subject
        expect(Storages::AutomaticallyManagedStorageSyncJob).to have_received(:debounce).with(project_storage.storage)
      end
    end
  end

  describe "OAUTH_CLIENT_TOKEN_CREATED" do
    subject { fire_event("OAUTH_CLIENT_TOKEN_CREATED") }

    context "when payload is empty" do
      let(:payload) { {} }

      it do
        subject
        expect(Storages::ManageStorageIntegrationsJob).not_to have_received(:debounce)
      end
    end

    context "when payload contains storage integration type" do
      let(:payload) { { integration_type: "Storages::Storage" } }

      it do
        subject
        expect(Storages::ManageStorageIntegrationsJob).to have_received(:debounce)
      end
    end
  end

  describe "ROLE_UPDATED" do
    subject { fire_event("ROLE_UPDATED") }

    context "when payload is empty" do
      let(:payload) { {} }

      it do
        subject
        expect(Storages::ManageStorageIntegrationsJob).not_to have_received(:debounce)
      end
    end

    context "when payload contains some nextcloud related permissions as a diff" do
      let(:payload) { { permissions_diff: [:read_files] } }

      it do
        subject
        expect(Storages::ManageStorageIntegrationsJob).to have_received(:debounce)
      end
    end
  end

  describe "ROLE_DESTROYED" do
    subject { fire_event("ROLE_DESTROYED") }

    context "when payload is empty" do
      let(:payload) { {} }

      it do
        subject
        expect(Storages::ManageStorageIntegrationsJob).not_to have_received(:debounce)
      end
    end

    context "when payload contains some nextcloud related permissions" do
      let(:payload) { { permissions: [:read_files] } }

      it do
        subject
        expect(Storages::ManageStorageIntegrationsJob).to have_received(:debounce)
      end
    end
  end
end
