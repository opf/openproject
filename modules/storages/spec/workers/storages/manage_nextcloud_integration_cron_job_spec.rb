# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'
require_module_spec_helper

RSpec.describe Storages::ManageNextcloudIntegrationCronJob, :webmock, type: :job do
  it 'has a schedule set' do
    expect(described_class.cron_expression).to eq('*/5 * * * *')
  end

  describe '.ensure_scheduled!' do
    before { ActiveJob::Base.disable_test_adapter }

    subject { described_class.ensure_scheduled! }

    context 'when there is active nextcloud project storage' do
      shared_let(:storage1) { create(:nextcloud_storage, :as_automatically_managed) }
      shared_let(:project_storage) { create(:project_storage, :as_automatically_managed, storage: storage1) }

      it 'schedules cron_job if not scheduled' do
        expect(described_class.scheduled?).to be(false)
        expect(described_class.delayed_job_query.count).to eq(0)

        subject

        expect(described_class.scheduled?).to be(true)
        expect(described_class.delayed_job_query.count).to eq(1)
      end

      it 'does not schedules cron_job if already scheduled' do
        described_class.ensure_scheduled!
        expect(described_class.scheduled?).to be(true)
        expect(described_class.delayed_job_query.count).to eq(1)

        subject

        expect(described_class.scheduled?).to be(true)
        expect(described_class.delayed_job_query.count).to eq(1)
      end
    end

    context 'when there is no active nextcloud project storage' do
      it 'does nothing but removes cron_job' do
        described_class.set(cron: described_class.cron_expression).perform_later
        expect(described_class.scheduled?).to be(true)
        expect(described_class.delayed_job_query.count).to eq(1)

        subject

        expect(described_class.scheduled?).to be(false)
        expect(described_class.delayed_job_query.count).to eq(0)
      end
    end
  end

  describe '.perform' do
    subject { described_class.new.perform }

    context 'when lock is free' do
      it 'responds with true' do
        expect(subject).to be(true)
      end

      it 'calls GroupFolderPropertiesSyncService for each automatically managed storage' do
        storage1 = create(:nextcloud_storage, :as_automatically_managed)
        storage2 = create(:nextcloud_storage, :as_not_automatically_managed)

        allow(Storages::GroupFolderPropertiesSyncService)
          .to receive(:call).with(storage1).and_return(ServiceResult.success)

        expect(subject).to be(true)

        expect(Storages::GroupFolderPropertiesSyncService).to have_received(:call).with(storage1).once
        expect(Storages::GroupFolderPropertiesSyncService).not_to have_received(:call).with(storage2)
      end

      it 'marks storage as healthy if sync was successful' do
        storage1 = create(:nextcloud_storage, :as_automatically_managed)

        allow(Storages::GroupFolderPropertiesSyncService)
          .to receive(:call).with(storage1).and_return(ServiceResult.success)

        Timecop.freeze('2023-03-14T15:17:00Z') do
          expect do
            subject
            storage1.reload
          end.to(
            change(storage1, :health_changed_at).to(Time.now.utc)
              .and(change(storage1, :health_status).from('pending').to('healthy'))
          )
        end
      end

      it 'marks storage as unhealthy if sync was unsuccessful' do
        storage1 = create(:nextcloud_storage, :as_automatically_managed)

        allow(Storages::GroupFolderPropertiesSyncService)
          .to receive(:call).with(storage1).and_return(ServiceResult.failure(errors: Storages::StorageError.new(code: :not_found)))

        Timecop.freeze('2023-03-14T15:17:00Z') do
          expect do
            subject
            storage1.reload
          end.to(
            change(storage1, :health_changed_at).to(Time.now.utc)
              .and(change(storage1, :health_status).from('pending').to('unhealthy'))
              .and(change(storage1, :health_reason).from(nil).to('not_found'))
          )
        end
      end
    end

    context 'when lock is unfree' do
      it 'responds with false' do
        allow(ApplicationRecord).to receive(:with_advisory_lock).and_return(false)

        expect(subject).to be(false)
        expect(ApplicationRecord).to have_received(:with_advisory_lock).with(
          'sync_all_group_folders',
          timeout_seconds: 0,
          transaction: false
        ).once
      end
    end
  end
end
