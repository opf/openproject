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

  subject { scheduled_job.perform }

  shared_let(:status_open) { create(:status, name: "open", is_closed: false) }
  shared_let(:status_closed) { create(:status, name: "closed", is_closed: true) }

  let(:scheduled_job) do
    described_class.ensure_scheduled!

    described_class.delayed_job
  end

  shared_let(:today) { Date.current }
  shared_let(:in_1_day) { today + 1.day }
  shared_let(:in_3_days) { today + 3.days }

  # Paris and Berlin are both UTC+01:00 (CET) or UTC+02:00 (CEST)
  shared_let(:user_paris) do
    create(
      :user,
      firstname: 'Paris',
      preferences: { time_zone: 'Europe/Paris' }
    )
  end
  shared_let(:user_berlin) do
    create(
      :user,
      firstname: 'Berlin',
      preferences: { time_zone: 'Europe/Berlin' }
    )
  end

  # Kathmandu is UTC+05:45 (no DST)
  shared_let(:user_kathmandu) do
    create(
      :user,
      firstname: 'Kathmandu',
      preferences: { time_zone: 'Asia/Kathmandu' }
    )
  end
  shared_let(:alertable_work_packages) do
    create_list(:work_package, 2)
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
      "expected user #{inspect_keys(user)} " \
        "to have a start date alert notification for work package " \
        "#{inspect_keys(work_package)}"
    end

    failure_message_when_negated do |user|
      "expected user #{inspect_keys(user)} " \
        "to NOT have a start date alert notification for work package " \
        "#{inspect_keys(work_package)}"
    end

    def inspect_keys(object)
      keys =
        case object
        when User then %i[id firstname]
        when WorkPackage then %i[id start_date due_date assigned_to_id responsible_id]
        end
      formatted_pairs = object
        .slice(*keys)
        .map { |k, v| "#{k}: #{v.is_a?(Date) ? v.to_s : v.inspect}" }
        .join(', ')
      "#<#{formatted_pairs}>"
    end
  end

  define :have_a_due_date_alert_notification_for do |work_package|
    match do |user|
      Notification
        .reason_date_alert_due_date
        .recipient(user)
        .exists?(resource: work_package)
    end

    failure_message do |user|
      "expected user #{inspect_keys(user)} " \
        "to have a due date alert notification for work package " \
        "#{inspect_keys(work_package)}"
    end

    failure_message_when_negated do |user|
      "expected user #{inspect_keys(user)} " \
        "to NOT have a due date alert notification for work package " \
        "#{inspect_keys(work_package)}"
    end

    def inspect_keys(object)
      keys =
        case object
        when User then %i[id firstname]
        when WorkPackage then %i[id start_date due_date assigned_to_id responsible_id]
        end
      formatted_pairs = object
        .slice(*keys)
        .map { |k, v| "#{k}: #{v.is_a?(Date) ? v.to_s : v.inspect}" }
        .join(', ')
      "#<#{formatted_pairs}>"
    end
  end

  def set_scheduled_time(run_at)
    scheduled_job.update_column(:run_at, run_at)
  end

  def alertable_work_package(attributes = {})
    assignee = attributes.slice(:responsible, :responsible_id).any? ? nil : user_paris
    attributes = attributes.reverse_merge(
      start_date: in_1_day,
      assigned_to: assignee
    )
    wp = alertable_work_packages.shift
    wp.update!(attributes)
    wp
  end

  describe '#perform' do
    let(:timezone_paris) { ActiveSupport::TimeZone[user_paris.preference.time_zone] }
    let(:timezone_kathmandu) { ActiveSupport::TimeZone[user_kathmandu.preference.time_zone] }

    it 'creates date alert notifications only for open work packages' do
      open_work_package = alertable_work_package(status: status_open)
      closed_work_package = alertable_work_package(status: status_closed)

      set_scheduled_time(timezone_paris.now.change(hour: 1, min: 0))
      travel_to(timezone_paris.now.change(hour: 1, min: 0))

      scheduled_job.invoke_job

      expect(user_paris).to have_a_start_date_alert_notification_for(open_work_package)
      expect(user_paris).not_to have_a_start_date_alert_notification_for(closed_work_package)
    end

    it 'creates date alert notifications only for users whose local time is 1:00 am when the job is executed' do
      work_package_for_paris_user = alertable_work_package(assigned_to: user_paris)
      work_package_for_kathmandu_user = alertable_work_package(assigned_to: user_kathmandu)

      set_scheduled_time(timezone_paris.now.change(hour: 1, min: 0))
      travel_to(timezone_paris.now.change(hour: 1, min: 4)) do
        scheduled_job.invoke_job

        expect(user_paris).to have_a_start_date_alert_notification_for(work_package_for_paris_user)
        expect(user_kathmandu).not_to have_a_start_date_alert_notification_for(work_package_for_kathmandu_user)
      end

      # change scheduled time and current time to cover kathmandu timezone
      set_scheduled_time(timezone_kathmandu.now.change(hour: 1, min: 0))
      travel_to(timezone_kathmandu.now.change(hour: 1, min: 4)) do
        scheduled_job.reload.invoke_job

        expect(user_kathmandu).to have_a_start_date_alert_notification_for(work_package_for_kathmandu_user)
      end
    end

    it 'creates date alert notifications if user is assigned to or accountable of the work package' do
      work_package_assigned = alertable_work_package(assigned_to: user_paris)
      work_package_accountable = alertable_work_package(responsible: user_paris)

      set_scheduled_time(timezone_paris.now.change(hour: 1, min: 0))
      travel_to(timezone_paris.now.change(hour: 1, min: 4)) do
        scheduled_job.invoke_job

        expect(user_paris).to have_a_start_date_alert_notification_for(work_package_assigned)
        expect(user_paris).to have_a_start_date_alert_notification_for(work_package_accountable)
      end
    end

    it 'creates start and finish date alert notifications based on user notification settings' do
      user_paris.notification_settings.first.update(
        start_date: 1,
        due_date: nil
      )
      user_berlin.notification_settings.first.update(
        start_date: nil,
        due_date: 3
      )
      work_package = alertable_work_package(assigned_to: user_paris,
                                            responsible: user_berlin,
                                            start_date: in_1_day,
                                            due_date: in_3_days)
      set_scheduled_time(timezone_paris.now.change(hour: 1, min: 0))
      travel_to(timezone_paris.now.change(hour: 1, min: 4)) do
        scheduled_job.invoke_job

        expect(user_paris).to have_a_start_date_alert_notification_for(work_package)
        expect(user_paris).not_to have_a_due_date_alert_notification_for(work_package)
        expect(user_berlin).not_to have_a_start_date_alert_notification_for(work_package)
        expect(user_berlin).to have_a_due_date_alert_notification_for(work_package)
      end
    end

    context 'when scheduled and executed at 01:00 am Paris local time' do
      it 'creates a start date alert notification for a user in the same time zone' do
        work_package = alertable_work_package

        set_scheduled_time(timezone_paris.now.change(hour: 1, min: 0))
        travel_to(timezone_paris.now.change(hour: 1, min: 0))

        scheduled_job.invoke_job

        expect(user_paris).to have_a_start_date_alert_notification_for(work_package)
      end
    end

    context 'when scheduled and executed at 01:14 am Paris local time' do
      it 'creates a start date alert notification for a user in the same time zone' do
        work_package = alertable_work_package
        set_scheduled_time(timezone_paris.now.change(hour: 1, min: 14))
        travel_to(timezone_paris.now.change(hour: 1, min: 14))

        scheduled_job.invoke_job

        expect(user_paris).to have_a_start_date_alert_notification_for(work_package)
      end
    end

    context 'when scheduled and executed at 01:15 am Paris local time' do
      it 'does not create a start date alert notification for a user in the same time zone' do
        work_package = alertable_work_package

        set_scheduled_time(timezone_paris.now.change(hour: 1, min: 15))
        travel_to(timezone_paris.now.change(hour: 1, min: 15))

        scheduled_job.invoke_job

        expect(user_paris).not_to have_a_start_date_alert_notification_for(work_package)
      end
    end
  end
end
