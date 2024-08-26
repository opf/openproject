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

RSpec.describe Notifications::CreateDateAlertsNotificationsJob, type: :job, with_ee: %i[date_alerts] do
  shared_let(:project) { create(:project, name: "main") }

  shared_let(:status_open) { create(:status, name: "open", is_closed: false) }
  shared_let(:status_closed) { create(:status, name: "closed", is_closed: true) }

  # Paris and Berlin are both UTC+01:00 (CET) or UTC+02:00 (CEST)
  shared_let(:timezone_paris) { ActiveSupport::TimeZone["Europe/Paris"] }
  shared_let(:timezone_berlin) { ActiveSupport::TimeZone["Europe/Berlin"] }
  # Kathmandu is UTC+05:45 (no DST)
  shared_let(:timezone_kathmandu) { ActiveSupport::TimeZone["Asia/Kathmandu"] }

  # use Paris time zone for most tests
  shared_let(:today) { timezone_paris.today }
  shared_let(:in_1_day) { today + 1.day }
  shared_let(:in_3_days) { today + 3.days }
  shared_let(:in_7_days) { today + 7.days }

  shared_let(:user) do
    create(
      :user,
      firstname: "Paris",
      preferences: { time_zone: timezone_paris.name }
    )
  end

  shared_let(:alertable_work_packages) do
    create_list(:work_package, 2, project:, author: user)
  end

  let(:job) { described_class }

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
                          .join(", ")
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
                          .join(", ")
      "#<#{formatted_pairs}>"
    end
  end

  def alertable_work_package(attributes = {})
    assignee = attributes.slice(:responsible, :responsible_id).any? ? nil : user
    attributes = attributes.reverse_merge(
      start_date: in_1_day,
      assigned_to: assignee
    )
    wp = alertable_work_packages.shift
    wp.update!(attributes)
    wp
  end

  # Converts "hh:mm" into { hour: h, min: m }
  def time_hash(time)
    %i[hour min].zip(time.split(":", 2).map(&:to_i)).to_h
  end

  def timezone_time(time, timezone)
    timezone.now.change(time_hash(time))
  end

  def run_job(local_time: "1:04", timezone: timezone_paris)
    travel_to(timezone_time(local_time, timezone)) do
      job.perform_now(user)

      yield
    end
  end

  describe "#perform" do
    it "creates date alert notifications only for open work packages" do
      open_work_package = alertable_work_package(status: status_open)
      closed_work_package = alertable_work_package(status: status_closed)

      run_job do
        expect(user).to have_a_start_date_alert_notification_for(open_work_package)
        expect(user).not_to have_a_start_date_alert_notification_for(closed_work_package)
      end
    end

    it "creates date alert notifications if user is assigned to the work package" do
      work_package_assigned = alertable_work_package(assigned_to: user)

      run_job do
        expect(user).to have_a_start_date_alert_notification_for(work_package_assigned)
      end
    end

    it "creates date alert notifications if user is accountable of the work package" do
      work_package_accountable = alertable_work_package(responsible: user)

      run_job do
        expect(user).to have_a_start_date_alert_notification_for(work_package_accountable)
      end
    end

    it "creates date alert notifications if user is watcher of the work package" do
      work_package_watched = alertable_work_package(responsible: nil)
      build(:watcher, watchable: work_package_watched, user:).save(validate: false)

      run_job do
        expect(user).to have_a_start_date_alert_notification_for(work_package_watched)
      end
    end

    it "creates start date alert notifications based on user notification settings" do
      user.notification_settings.first.update(
        start_date: 1,
        due_date: nil
      )
      work_package = alertable_work_package(assigned_to: user,
                                            start_date: in_1_day,
                                            due_date: in_3_days)

      run_job do
        expect(user).to have_a_start_date_alert_notification_for(work_package)
        expect(user).not_to have_a_due_date_alert_notification_for(work_package)
      end
    end

    it "creates due date alert notifications based on user notification settings" do
      user.notification_settings.first.update(
        start_date: nil,
        due_date: 3
      )
      work_package = alertable_work_package(assigned_to: user,
                                            start_date: in_1_day,
                                            due_date: in_3_days)

      run_job do
        expect(user).not_to have_a_start_date_alert_notification_for(work_package)
        expect(user).to have_a_due_date_alert_notification_for(work_package)
      end
    end

    context "without enterprise token", with_ee: false do
      it "does not create any date alerts" do
        work_package = alertable_work_package

        run_job do
          expect(user).not_to have_a_start_date_alert_notification_for(work_package)
        end
      end
    end

    context "when project notification settings are defined for a user" do
      it "creates date alert notifications using these settings for work packages of the project" do
        # global notification settings
        user.notification_settings.first.update(
          start_date: 1,
          due_date: nil
        )
        # project notifications settings
        user.notification_settings.create(
          project:,
          start_date: nil,
          due_date: 7
        )
        silent_work_package = alertable_work_package(assigned_to: user,
                                                     project:,
                                                     start_date: in_1_day,
                                                     due_date: in_1_day)
        noisy_work_package = alertable_work_package(assigned_to: user,
                                                    project:,
                                                    start_date: in_7_days,
                                                    due_date: in_7_days)

        run_job do
          expect(user).not_to have_a_start_date_alert_notification_for(silent_work_package)
          expect(user).not_to have_a_due_date_alert_notification_for(silent_work_package)
          expect(user).not_to have_a_start_date_alert_notification_for(noisy_work_package)
          expect(user).to have_a_due_date_alert_notification_for(noisy_work_package)
        end
      end
    end

    context "with existing date alerts" do
      it "marks them as read when new ones are created" do
        work_package = alertable_work_package(assigned_to: user,
                                              start_date: in_1_day,
                                              due_date: in_1_day)
        existing_start_notification = create(:notification,
                                             resource: work_package,
                                             recipient: user,
                                             reason: :date_alert_start_date)
        existing_due_notification = create(:notification,
                                           resource: work_package,
                                           recipient: user,
                                           reason: :date_alert_due_date)

        run_job do
          expect(existing_start_notification.reload).to have_attributes(read_ian: true)
          expect(existing_due_notification.reload).to have_attributes(read_ian: true)
          unread_date_alert_notifications = Notification.where(recipient: user,
                                                               read_ian: false,
                                                               resource: work_package)
          expect(unread_date_alert_notifications.pluck(:reason))
            .to contain_exactly("date_alert_start_date", "date_alert_due_date")
        end
      end

      # rubocop:disable RSpec/ExampleLength
      it "does not mark them as read when if no new notifications are created" do
        work_package_start = alertable_work_package(assigned_to: user,
                                                    start_date: in_1_day,
                                                    due_date: nil)
        work_package_due = alertable_work_package(assigned_to: user,
                                                  start_date: nil,
                                                  due_date: in_1_day)
        existing_wp_start_start_notif = create(:notification,
                                               reason: :date_alert_start_date,
                                               recipient: user,
                                               resource: work_package_start)
        existing_wp_start_due_notif = create(:notification,
                                             reason: :date_alert_due_date,
                                             recipient: user,
                                             resource: work_package_start)
        existing_wp_due_start_notif = create(:notification,
                                             reason: :date_alert_start_date,
                                             recipient: user,
                                             resource: work_package_due)
        existing_wp_due_due_notif = create(:notification,
                                           reason: :date_alert_due_date,
                                           recipient: user,
                                           resource: work_package_due)

        run_job do
          expect(existing_wp_start_start_notif.reload).to have_attributes(read_ian: true)
          expect(existing_wp_start_due_notif.reload).to have_attributes(read_ian: false)
          expect(existing_wp_due_start_notif.reload).to have_attributes(read_ian: false)
          expect(existing_wp_due_due_notif.reload).to have_attributes(read_ian: true)
        end
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end
end
