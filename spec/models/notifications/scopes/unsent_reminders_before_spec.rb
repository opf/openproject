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

RSpec.describe Notifications::Scopes::UnsentRemindersBefore do
  describe ".unsent_reminders_before" do
    subject(:scope) { Notification.unsent_reminders_before(recipient:, time:) }

    let(:recipient) do
      create(:user)
    end
    let(:time) do
      Time.current
    end

    let!(:notification) do
      create(:notification,
             recipient: notification_recipient,
             read_ian: notification_read_ian,
             mail_reminder_sent: notification_mail_reminder_sent,
             mail_alert_sent: notification_mail_alert_sent,
             created_at: notification_created_at)
    end
    let(:notification_mail_reminder_sent) { false }
    let(:notification_mail_alert_sent) { false }
    let(:notification_read_ian) { false }
    let(:notification_created_at) { 10.minutes.ago }
    let(:notification_recipient) { recipient }

    context "with an unread, not alerted about and not reminded notification that was created before the time and for the user" do
      it "returns the notification" do
        expect(scope).to contain_exactly(notification)
      end
    end

    context "with a notification that was created after the time" do
      let(:notification_created_at) { 10.minutes.from_now }

      it { is_expected.to be_empty }
    end

    context "with a notification that was created for different user" do
      let(:notification_recipient) { create(:user) }

      it { is_expected.to be_empty }
    end

    context "with a notification reminded mark set to nil" do
      let(:notification_mail_reminder_sent) { nil }

      it { is_expected.to be_empty }
    end

    context "with a reminded notification" do
      let(:notification_mail_reminder_sent) { true }

      it { is_expected.to be_empty }
    end

    context "with a notification read mark set to nil" do
      let(:notification_read_ian) { nil }

      it "returns the notification" do
        expect(scope).to contain_exactly(notification)
      end
    end

    context "with a read notification" do
      let(:notification_read_ian) { true }

      it { is_expected.to be_empty }
    end

    context "with a notification alert mark set to nil" do
      let(:notification_mail_alert_sent) { nil }

      it "returns the notification" do
        expect(scope).to contain_exactly(notification)
      end
    end

    context "with a notification about which user was already alerted" do
      let(:notification_mail_alert_sent) { true }

      it { is_expected.to be_empty }
    end
  end
end
