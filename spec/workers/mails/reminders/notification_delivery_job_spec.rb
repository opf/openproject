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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Mails::Reminders::NotificationDeliveryJob do
  shared_let(:work_package) { create(:work_package) }
  shared_let(:user) { create(:user) }

  shared_let(:notification) do
    reminder = create(:reminder, remindable: work_package, creator: user)
    create(:notification, reason: :reminder, recipient: user, resource: work_package, reminder:)
  end

  before do
    allow(Reminders::NotificationMailer).to receive(:reminder_notification).and_call_original
  end

  describe "#perform" do
    subject { described_class.new.perform(notification) }

    it "sends the reminder notification" do
      expect { subject }.to change(ActionMailer::Base.deliveries, :count).by(1)
      expect(Reminders::NotificationMailer).to have_received(:reminder_notification).with(notification)

      aggregate_failures "notification marked as sent" do
        notification.reload
        expect(notification.mail_alert_sent).to be(true)
      end
    end
  end
end
