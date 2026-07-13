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

RSpec.describe Reminders::ScheduleReminderJob do
  describe ".schedule" do
    let(:reminder) { create(:reminder) }

    subject { described_class.schedule(reminder) }

    it "enqueues a ScheduleReminderJob" do
      expect { subject }
        .to have_enqueued_job(described_class)
              .at(reminder.remind_at)
              .with(reminder)
    end
  end

  describe "#perform" do
    let(:role) { create(:project_role, permissions: %i[view_work_packages]) }
    let(:project) { create(:project) }
    let(:user) { create(:user, member_with_roles: { project => role }) }
    let(:work_package) { create(:work_package, project:) }
    let(:reminder) { create(:reminder, creator: user, remindable: work_package) }

    subject { described_class.new.perform(reminder) }

    it "creates a notification from the reminder" do
      notification_svc = nil
      expect { notification_svc = subject }.to change(Notification, :count).by(1) & change(ReminderNotification, :count).by(1)

      aggregate_failures "notification attributes" do
        notification = notification_svc.result

        expect(notification.recipient_id).to eq(reminder.creator_id)
        expect(notification.resource).to eq(reminder.remindable)
        expect(notification.reason).to eq("reminder")
      end

      aggregate_failures "marks reminder as having unread notifications" do
        expect(reminder.reload).to be_an_unread_notification
      end
    end

    context "when the creator no longer has access to the remindable" do
      before { Member.where(principal: user, project:).destroy_all }

      it "does not create a notification" do
        expect { subject }.not_to change(Notification, :count)
      end

      it "does not enqueue a NotificationDeliveryJob" do
        expect { subject }
          .not_to have_enqueued_job(Mails::Reminders::NotificationDeliveryJob)
      end

      it "marks the reminder as completed" do
        subject
        expect(reminder.reload).to be_completed
      end
    end

    context "when the reminder is already notified" do
      before do
        create(:reminder_notification, reminder: reminder, notification: create(:notification, read_ian: false))
      end

      it "does not create a notification from the reminder" do
        expect { subject }.not_to change(Notification, :count)
      end
    end

    context "when the recipient has immediate reminders enabled" do
      it "enqueues a NotificationDeliveryJob" do
        expect { subject }
          .to have_enqueued_job(Mails::Reminders::NotificationDeliveryJob)
                .with(a_kind_of(Notification))
      end
    end

    context "when the recipient has immediate reminders disabled" do
      before do
        recipient = reminder.creator
        recipient.pref.immediate_reminders = { personal_reminder: false }
        recipient.pref.save
      end

      it "does not enqueue a NotificationDeliveryJob" do
        expect { subject }
          .not_to have_enqueued_job(Mails::Reminders::NotificationDeliveryJob)
      end
    end
  end
end
