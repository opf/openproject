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

RSpec.describe Mails::ReminderJob, type: :model do
  subject(:job) { described_class.perform_now(recipient) }

  let(:recipient) do
    build_stubbed(:user)
  end

  let(:notification_ids) { [1, 2, 3] }

  let!(:notifications) do
    class_double(Notification).tap do |notifications|
      allow(Time)
        .to receive(:current)
              .and_return(Time.current)

      allow(Notification)
        .to receive(:unsent_reminders_before)
              .with(recipient:, time: Time.current)
              .and_return(notifications)

      allow(notifications)
        .to receive(:visible)
              .with(recipient)
              .and_return(notifications)

      allow(notifications)
        .to receive(:pluck)
              .with(:id)
              .and_return(notification_ids)

      allow(Notification)
        .to receive(:where)
              .with(id: notification_ids)
              .and_return(notifications)

      allow(notifications)
        .to receive(:update_all)
    end
  end

  let(:mail) { instance_double(ActionMailer::MessageDelivery, deliver_now: nil) }

  before do
    # make sure no actual calls make it into the DigestMailer
    allow(DigestMailer)
      .to receive(:work_packages)
            .with(recipient&.id, notification_ids)
            .and_return(mail)
  end

  describe "#perform" do
    context "with successful mail sending" do
      it "sends a mail" do
        job
        expect(DigestMailer)
          .to have_received(:work_packages)
                .with(recipient.id, notification_ids)
      end

      it "marks the notifications as read" do
        job

        expect(notifications)
          .to have_received(:update_all)
                .with(mail_reminder_sent: true, updated_at: Time.current)
      end

      it "impersonates the recipient" do
        allow(DigestMailer).to receive(:work_packages) do
          expect(User.current)
            .eql receiver
        end

        job
      end
    end

    context "without a recipient" do
      let(:recipient) { nil }

      it "sends no mail" do
        job
        expect(DigestMailer)
          .not_to have_received(:work_packages)
      end
    end

    context "with an error on mail rendering" do
      before do
        allow(DigestMailer)
          .to receive(:work_packages)
                .and_raise("error")
      end

      it "swallows the error" do
        expect { job }
          .not_to raise_error
      end
    end

    context "with an error on mail sending" do
      before do
        allow(mail)
          .to receive(:deliver_now)
                .and_raise(SocketError)
      end

      it "raises the error" do
        expect { job }
          .to raise_error(SocketError)
      end
    end

    context "with an empty list of notification ids" do
      let(:notification_ids) { [] }

      it "sends no mail" do
        job
        expect(DigestMailer)
          .not_to have_received(:work_packages)
      end
    end
  end
end
