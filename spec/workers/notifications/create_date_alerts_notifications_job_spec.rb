#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Notifications::CreateDateAlertsNotificationsJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  create_shared_association_defaults_for_work_package_factory

  subject { scheduled_job.invoke_job }

  let(:scheduled_job) do
    described_class.ensure_scheduled!

    Delayed::Job.first
  end

  let(:today) { Date.current }
  let(:in_1_day) { today + 1.day }

  let(:user_paris) do
    create(
      :user,
      firstname: 'Europe/Paris',
      preferences: { time_zone: 'Europe/Paris' }
    )
  end
  let(:user_kathmandu) do
    create(
      :user,
      firstname: 'Asia/Kathmandu',
      preferences: { time_zone: 'Asia/Kathmandu' }
    )
  end

  before do
    # We need to access the job as stored in the database to get at the run_at time persisted there
    allow(ActiveJob::Base)
      .to receive(:queue_adapter)
            .and_return(ActiveJob::QueueAdapters::DelayedJobAdapter.new)
  end

  define :have_a_start_date_alert_notification_for do |work_package|
    match do |user|
      Notification
        .reason_date_alert_start_date
        .recipient(user)
        .exists?(resource: work_package)
    end

    failure_message do |user|
      "expected user #{inspect_keys(user, :id, :firstname)} " \
        "to have a start date alert notification for work package " \
        "#{inspect_keys(work_package, :id, :start_date, :due_date)}"
    end

    failure_message_when_negated do |user|
      "expected user #{inspect_keys(user, :id, :firstname)} " \
        "to NOT have a start date alert notification for work package " \
        "#{inspect_keys(work_package, :id, :start_date, :due_date)}"
    end

    def inspect_keys(object, *keys)
      formatted_pairs = object
        .slice(*keys)
        .map { |k, v| "#{k}: #{v.is_a?(Date) ? v.to_s : v.inspect}" }
        .join(', ')
      "#<#{formatted_pairs}>"
    end
  end

  def set_run_at(run_at)
    scheduled_job.update_column(:run_at, run_at)
  end

  describe '#perform' do
    let(:timezone_paris) { ActiveSupport::TimeZone[user_paris.preference.time_zone] }

    context 'when scheduled and executed at 01:00 am Paris local time' do
      it 'creates a start date alert notification for a user in the same time zone' do
        set_run_at(timezone_paris.now.change(hour: 1, min: 0))
        travel_to(timezone_paris.now.change(hour: 1, min: 0))
        work_package = create(:work_package,
                              start_date: in_1_day,
                              assigned_to: user_paris)

        scheduled_job.invoke_job

        expect(user_paris).to have_a_start_date_alert_notification_for(work_package)
      end

      it 'does not create a start date alert notification for a user in another time zone' do
        set_run_at(timezone_paris.now.change(hour: 1, min: 0))
        travel_to(timezone_paris.now.change(hour: 1, min: 0))
        work_package = create(:work_package,
                              start_date: in_1_day,
                              assigned_to: user_kathmandu)

        scheduled_job.invoke_job

        expect(user_kathmandu).not_to have_a_start_date_alert_notification_for(work_package)
      end
    end

    context 'when running at 01:14 am Paris local time' do
      it 'creates a start date alert notification for a user in the same time zone' do
        set_run_at(timezone_paris.now.change(hour: 1, min: 14))
        travel_to(timezone_paris.now.change(hour: 1, min: 14))
        work_package = create(:work_package,
                              start_date: in_1_day,
                              assigned_to: user_paris)

        scheduled_job.invoke_job

        expect(user_paris).to have_a_start_date_alert_notification_for(work_package)
      end
    end

    context 'when running at 01:15 am Paris local time' do
      it 'does not create a start date alert notification for a user in the same time zone' do
        set_run_at(timezone_paris.now.change(hour: 1, min: 15))
        travel_to(timezone_paris.now.change(hour: 1, min: 15))
        work_package = create(:work_package,
                              start_date: in_1_day,
                              assigned_to: user_paris)

        scheduled_job.invoke_job

        expect(user_paris).not_to have_a_start_date_alert_notification_for(work_package)
      end
    end
  end
end
