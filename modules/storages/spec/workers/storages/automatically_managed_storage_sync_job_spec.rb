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

RSpec.describe Storages::AutomaticallyManagedStorageSyncJob, type: :job do
  let(:managed_nextcloud) { create(:nextcloud_storage_configured, :as_automatically_managed) }

  describe ".debounce" do
    context "when has been debounced by other thread" do
      it "does not change the number of enqueued jobs" do
        expect(performed_jobs.count).to eq(0)
        expect(described_class.debounce(managed_nextcloud).successfully_enqueued?).to be(true)
        expect(described_class.debounce(managed_nextcloud)).to be(false)
        expect(enqueued_jobs.count).to eq(1)

        expect { described_class.debounce(managed_nextcloud) }.not_to change(enqueued_jobs, :count)
      end
    end

    context "when has not been debounced by other thread" do
      before { RequestStore.delete("sync-nextcloud-#{managed_nextcloud.id}") }

      it "schedules a job" do
        expect { described_class.debounce(managed_nextcloud) }.to change(enqueued_jobs, :count).from(0).to(1)
      end
    end
  end

  describe ".perform" do
    subject(:job_instance) { described_class.new }

    it "only runs for automatically managed storages" do
      unmanaged_nextcloud = create(:nextcloud_storage_configured, :as_not_automatically_managed)

      allow(Storages::NextcloudGroupFolderPropertiesSyncService)
        .to receive(:call).with(managed_nextcloud).and_return(ServiceResult.success)

      job_instance.perform(managed_nextcloud)
      job_instance.perform(unmanaged_nextcloud)

      expect(Storages::NextcloudGroupFolderPropertiesSyncService).to have_received(:call).with(managed_nextcloud)
      expect(Storages::NextcloudGroupFolderPropertiesSyncService).not_to have_received(:call).with(unmanaged_nextcloud)
    end

    it "marks storage as healthy if sync was successful" do
      allow(Storages::NextcloudGroupFolderPropertiesSyncService)
        .to receive(:call).with(managed_nextcloud).and_return(ServiceResult.success)

      Timecop.freeze("2023-03-14T15:17:00Z") do
        expect do
          job_instance.perform(managed_nextcloud)
          managed_nextcloud.reload
        end.to(
          change(managed_nextcloud, :health_changed_at).to(Time.now.utc)
                                              .and(change(managed_nextcloud, :health_status).from("pending").to("healthy"))
        )
      end
    end

    it "marks storage as unhealthy if sync was unsuccessful" do
      job = class_double(Storages::HealthStatusMailerJob)
      allow(Storages::HealthStatusMailerJob).to receive(:set).and_return(job)
      allow(job).to receive(:perform_later)

      errors = ActiveModel::Errors.new(Storages::NextcloudGroupFolderPropertiesSyncService.new(managed_nextcloud))
      errors.add(:remote_folders, :not_found, group_folder: managed_nextcloud.group_folder)

      allow(Storages::NextcloudGroupFolderPropertiesSyncService)
        .to receive(:call)
              .with(managed_nextcloud)
              .and_return(ServiceResult.failure(errors:))

      Timecop.freeze("2023-03-14T15:17:00Z") do
        expect do
          perform_enqueued_jobs { described_class.perform_later(managed_nextcloud) }
          managed_nextcloud.reload
        end.to(
          change(managed_nextcloud, :health_changed_at).to(Time.now.utc)
                                              .and(change(managed_nextcloud, :health_status).from("pending").to("unhealthy"))
                                              .and(change(managed_nextcloud, :health_reason).from(nil).to(/wasn't found/))
        )
      end
    end

    context "when Storages::Errors::IntegrationJobError is raised" do
      before do
        errors = ActiveModel::Errors.new(Storages::NextcloudGroupFolderPropertiesSyncService.new(managed_nextcloud))
        errors.add(:base, :error)

        allow(Storages::NextcloudGroupFolderPropertiesSyncService)
          .to receive(:call).with(managed_nextcloud)
                            .and_return(ServiceResult.failure(errors:))

        allow(OpenProject::Notifications).to receive(:send)
      end

      it "retries the job" do
        perform_enqueued_jobs { described_class.perform_later(managed_nextcloud) }
        performed_jobs = described_class.queue_adapter.performed_jobs

        expect(performed_jobs.last.dig("exception_executions", "[Storages::Errors::IntegrationJobError]")).to eq(5)
      end

      it "sends a notification after the maximum number of attempts" do
        perform_enqueued_jobs { described_class.perform_later(managed_nextcloud) }

        expect(OpenProject::Notifications).to have_received(:send).with(
          OpenProject::Events::STORAGE_TURNED_UNHEALTHY,
          storage: managed_nextcloud,
          reason: /unexpected error occurred/
        )
      end
    end
  end
end
