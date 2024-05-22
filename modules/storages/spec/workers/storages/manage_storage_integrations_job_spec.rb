# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe Storages::ManageStorageIntegrationsJob, :webmock, type: :job do
  describe ".debounce" do
    context "when has been debounced by other thread" do
      before { ActiveJob::Base.disable_test_adapter }

      it "does not change the number of enqueued jobs" do
        expect(GoodJob::Job.count).to eq(0)
        expect(described_class.perform_later.successfully_enqueued?).to be(true)
        expect(described_class.perform_later).to be(false)
        expect(GoodJob::Job.count).to eq(1)

        expect { described_class.debounce }.not_to change(GoodJob::Job, :count)
      end
    end

    context "when has not been debounced by other thread" do
      it "schedules a job" do
        expect { described_class.debounce }.to change(enqueued_jobs, :count).from(0).to(1)
      end

      it "tries to schedule once when called 1000 times in a short period of time" do
        expect_any_instance_of(ActiveJob::ConfiguredJob)
          .to receive(:perform_later).once.and_call_original

        expect do
          1000.times { described_class.debounce }
        end.to change(enqueued_jobs, :count).from(0).to(1)
      end
    end
  end

  describe ".disable_cron_job_if_needed" do
    before { ActiveJob::Base.disable_test_adapter }

    subject { described_class.disable_cron_job_if_needed }

    context "when there is an active nextcloud project storage" do
      shared_let(:storage1) { create(:nextcloud_storage, :as_automatically_managed) }
      shared_let(:project_storage) { create(:project_storage, :as_automatically_managed, storage: storage1) }

      it "enables the cron_job if was disabled before" do
        GoodJob::Setting.cron_key_disable(described_class::CRON_JOB_KEY)

        good_job_setting = GoodJob::Setting.first
        expect(good_job_setting.key).to eq("cron_keys_disabled")
        expect(good_job_setting.value).to eq(["Storages::ManageStorageIntegrationsJob"])

        expect { subject }.not_to change(GoodJob::Setting, :count).from(1)

        good_job_setting.reload
        expect(good_job_setting.key).to eq("cron_keys_disabled")
        expect(good_job_setting.value).to eq([])
      end

      it "does nothing if the cron_job is not disabled" do
        expect(GoodJob::Setting.cron_key_enabled?(described_class::CRON_JOB_KEY)).to be(true)

        expect { subject }.not_to change(GoodJob::Setting, :count).from(0)

        expect(GoodJob::Setting.cron_key_enabled?(described_class::CRON_JOB_KEY)).to be(true)
      end
    end

    context "when there is no active nextcloud project storage" do
      it "disables the cron job" do
        expect { subject }.to change(GoodJob::Setting, :count).from(0).to(1)

        good_job_setting = GoodJob::Setting.first
        expect(good_job_setting.key).to eq("cron_keys_disabled")
        expect(good_job_setting.value).to eq(["Storages::ManageStorageIntegrationsJob"])
      end
    end
  end

  describe ".perform" do
    let(:storage1) { create(:nextcloud_storage_configured, :as_automatically_managed) }

    subject { described_class.new.perform }

    it "calls NextcloudGroupFolderPropertiesSyncService for each automatically managed storage" do
      storage2 = create(:nextcloud_storage, :as_not_automatically_managed)
      storage3 = create(:nextcloud_storage, :as_automatically_managed)

      allow(Storages::NextcloudGroupFolderPropertiesSyncService)
        .to receive(:call).with(storage1).and_return(ServiceResult.success)

      subject

      expect(Storages::NextcloudGroupFolderPropertiesSyncService).to have_received(:call).with(storage1).once
      expect(Storages::NextcloudGroupFolderPropertiesSyncService).not_to have_received(:call).with(storage2)
      expect(Storages::NextcloudGroupFolderPropertiesSyncService).not_to have_received(:call).with(storage3)
    end

    it "marks storage as healthy if sync was successful" do
      allow(Storages::NextcloudGroupFolderPropertiesSyncService)
        .to receive(:call).with(storage1).and_return(ServiceResult.success)

      Timecop.freeze("2023-03-14T15:17:00Z") do
        expect do
          subject
          storage1.reload
        end.to(
          change(storage1, :health_changed_at).to(Time.now.utc)
                                              .and(change(storage1, :health_status).from("pending").to("healthy"))
        )
      end
    end

    it "marks storage as unhealthy if sync was unsuccessful" do
      job = class_double(Storages::HealthStatusMailerJob)
      allow(Storages::HealthStatusMailerJob).to receive(:set).and_return(job)
      allow(job).to receive(:perform_later)

      allow(Storages::NextcloudGroupFolderPropertiesSyncService)
        .to receive(:call)
              .with(storage1)
              .and_return(ServiceResult.failure(errors: Storages::StorageError.new(code: :not_found)))

      Timecop.freeze("2023-03-14T15:17:00Z") do
        expect do
          perform_enqueued_jobs { described_class.perform_later }
          storage1.reload
        end.to(
          change(storage1, :health_changed_at).to(Time.now.utc)
                                              .and(change(storage1, :health_status).from("pending").to("unhealthy"))
                                              .and(change(storage1, :health_reason).from(nil).to("not_found"))
        )
      end
    end

    context "when Storages::Errors::IntegrationJobError is raised" do
      before do
        allow(Storages::NextcloudGroupFolderPropertiesSyncService)
          .to receive(:call).with(storage1)
                            .and_return(ServiceResult.failure(errors: Storages::StorageError.new(code: :custom_error)))
      end

      it "retries the job" do
        allow(OpenProject::Notifications).to receive(:send)

        perform_enqueued_jobs { described_class.perform_later }

        expect(described_class
                 .queue_adapter.performed_jobs
                 .last.dig("exception_executions", "[Storages::Errors::IntegrationJobError]")).to eq(5)
      end

      it "sends a notification after the maximum number of attempts" do
        allow(OpenProject::Notifications).to receive(:send)

        perform_enqueued_jobs { described_class.perform_later }

        expect(OpenProject::Notifications).to have_received(:send).with(
          OpenProject::Events::STORAGE_TURNED_UNHEALTHY,
          storage: storage1,
          reason: "custom_error"
        )
      end
    end
  end
end
