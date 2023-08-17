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

RSpec.describe Storages::ManageNextcloudIntegrationEventsJob, type: :job do
  describe '.priority' do
    it 'has a maximum priority' do
      expect(described_class.priority).to eq(7)
    end
  end

  describe '.debounce' do
    it 'debounces job with 1 minute timeframe' do
      ActiveJob::Base.disable_test_adapter

      other_handler = Storages::ManageNextcloudIntegrationCronJob.perform_later.provider_job_id
      same_handler_within_timeframe1 = described_class.set(wait: 1.second).perform_later.provider_job_id
      same_handler_within_timeframe2 = described_class.set(wait: 2.seconds).perform_later.provider_job_id
      same_handler_within_timeframe3 = described_class.set(wait: 3.seconds).perform_later.provider_job_id
      same_handler_out_of_timeframe = described_class.set(wait: 1.minute).perform_later.provider_job_id
      same_handler_within_timeframe_in_progress = described_class.set(wait: 18.seconds).perform_later.tap do |job|
        # simulate in progress state
        Delayed::Job.where(id: job.provider_job_id).update_all(locked_at: Time.current, locked_by: "test_process #{Process.pid}")
      end.provider_job_id

      expect(Delayed::Job.count).to eq(6)

      described_class.debounce

      expect(Delayed::Job.count).to eq(4)
      expect(Delayed::Job.pluck(:id)).to include(other_handler,
                                                 same_handler_out_of_timeframe,
                                                 same_handler_within_timeframe_in_progress)
      expect(Delayed::Job.pluck(:id)).not_to include(same_handler_within_timeframe1,
                                                     same_handler_within_timeframe2,
                                                     same_handler_within_timeframe3)
      expect(
        Delayed::Job
          .where("handler LIKE ?", "%job_class: #{described_class}%")
          .last
          .run_at
      ).to be_within(3.seconds).of(described_class::DEBOUNCE_TIME.from_now)
    end
  end

  describe '#perform' do
    subject { described_class.new.perform }

    it 'works out silently' do
      allow(Storages::NextcloudStorage).to receive(:sync_all_group_folders).and_return(true)
      subject
    end

    it 'debounces itself when sync has been started by another process' do
      allow(Storages::NextcloudStorage).to receive(:sync_all_group_folders).and_return(false)
      allow(described_class).to receive(:debounce)

      subject

      expect(described_class).to have_received(:debounce).once
    end
  end
end
