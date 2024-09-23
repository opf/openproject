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

RSpec.describe Storages::ManageStorageIntegrationsJob, type: :job do
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

    context "when there is an active nextcloud project storage" do
      shared_let(:storage1) { create(:nextcloud_storage, :as_automatically_managed) }
      shared_let(:project_storage) { create(:project_storage, :as_automatically_managed, storage: storage1) }

      it "enables the cron_job if was disabled before" do
        GoodJob::Setting.cron_key_disable(described_class::CRON_JOB_KEY)

        good_job_setting = GoodJob::Setting.first
        expect(good_job_setting.key).to eq("cron_keys_disabled")
        expect(good_job_setting.value).to eq(["Storages::ManageStorageIntegrationsJob"])

        expect { described_class.disable_cron_job_if_needed }.not_to change(GoodJob::Setting, :count).from(1)

        good_job_setting.reload
        expect(good_job_setting.key).to eq("cron_keys_disabled")
        expect(good_job_setting.value).to eq([])
      end

      it "does nothing if the cron_job is not disabled" do
        expect(GoodJob::Setting.cron_key_enabled?(described_class::CRON_JOB_KEY)).to be(true)

        expect { described_class.disable_cron_job_if_needed }.not_to change(GoodJob::Setting, :count).from(0)

        expect(GoodJob::Setting.cron_key_enabled?(described_class::CRON_JOB_KEY)).to be(true)
      end
    end

    context "when there is no active nextcloud project storage" do
      it "disables the cron job" do
        expect { described_class.disable_cron_job_if_needed }.to change(GoodJob::Setting, :count).from(0).to(1)

        good_job_setting = GoodJob::Setting.first
        expect(good_job_setting.key).to eq("cron_keys_disabled")
        expect(good_job_setting.value).to eq(["Storages::ManageStorageIntegrationsJob"])
      end
    end
  end

  describe ".perform" do
    before do
      create(:nextcloud_storage_configured, :as_automatically_managed)
      create(:nextcloud_storage, :as_not_automatically_managed)
      create(:sharepoint_dev_drive_storage, :as_automatically_managed)
    end

    it "enqueues a job for each automatically managed storage" do
      expect { described_class.perform_now }.to change(enqueued_jobs, :count).by(2)
    end
  end
end
