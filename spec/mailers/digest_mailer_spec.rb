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

RSpec.describe DigestMailer do
  include OpenProject::ObjectLinking
  include ActionView::Helpers::UrlHelper
  include OpenProject::StaticRouting::UrlHelpers
  include Redmine::I18n

  let(:recipient) do
    build_stubbed(:user).tap do |u|
      allow(User)
        .to receive(:find)
              .with(u.id)
              .and_return(u)
    end
  end
  let(:project1) { build_stubbed(:project) }

  let(:work_package) do
    build_stubbed(:work_package,
                  type: build_stubbed(:type))
  end
  let(:journal) do
    build_stubbed(:work_package_journal,
                  notes: "Some notes").tap do |j|
      allow(j)
        .to receive(:details)
              .and_return({ "subject" => ["old subject", "new subject"] })
    end
  end
  let(:notifications) do
    [build_stubbed(:notification,
                   resource: work_package,
                   reason: :commented,
                   journal:)].tap do |notifications|
      allow(Notification)
        .to receive(:where)
              .and_return(notifications)

      without_partial_double_verification do
        allow(notifications)
          .to receive(:includes)
                .and_return(notifications)
      end
    end
  end

  describe "#work_packages" do
    subject(:mail) { described_class.work_packages(recipient.id, notifications.map(&:id)) }

    let(:mail_body) { mail.body.parts.detect { |part| part["Content-Type"].value == "text/html" }.body.to_s }

    it "notes the day and the number of notifications in the subject" do
      expect(mail.subject)
        .to eql "OpenProject - 1 unread notification"
    end

    it "sends to the recipient" do
      expect(mail.to)
        .to contain_exactly(recipient.mail)
    end

    it "sets the expected message_id header" do
      allow(Time)
        .to receive(:current)
              .and_return(Time.current)

      expect(mail.message_id)
        .to eql "op.digest.#{Time.current.strftime('%Y%m%d%H%M%S')}.#{recipient.id}@example.net"
    end

    it "sets the expected openproject headers" do
      expect(mail["X-OpenProject-User"]&.value)
        .to eql recipient.name
    end

    it "includes the notifications grouped by work package" do
      time_stamp = format_time(journal.created_at)
      expect(mail_body)
        .to have_text("Hello #{recipient.firstname}")

      expected_notification_subject = "#{work_package.type.name.upcase} #{work_package.subject}"
      expect(mail_body)
        .to have_text(expected_notification_subject, normalize_ws: true)

      expected_notification_header = "#{work_package.status.name} ##{work_package.id} - #{work_package.project}"
      expect(mail_body)
        .to have_text(expected_notification_header, normalize_ws: true)

      expected_text = "#{journal.initial? ? 'Created' : 'Updated'} at #{time_stamp} by #{recipient.name}"
      expect(mail_body)
        .to have_text(expected_text, normalize_ws: true)
    end

    context "with only a deleted work package for the digest" do
      let(:work_package) { nil }

      it "is a NullMail which isn't sent" do
        expect(mail.body)
          .to eql ""

        expect(mail.header)
          .to eql({})
      end
    end

    describe "#date_alerts_text" do
      let!(:project1) { create(:project) }
      let!(:recipient) { create(:user) }
      let(:notifications) { [notification] }

      context "when notification_wp_start_past" do
        let(:work_package) do
          create(:work_package, subject: "WP start past", project: project1, start_date: 1.day.ago, type: Type.first)
        end
        let(:notification) do
          create(:notification,
                 reason: :date_alert_start_date,
                 recipient:,
                 resource: work_package)
        end

        it "matches generated text" do
          expect(mail_body).to have_text("Start date was 1 day ago")
        end
      end

      context "when notification_wp_start_future" do
        let(:work_package) do
          create(:work_package, subject: "WP start future", project: project1, start_date: 2.days.from_now, type: Type.first)
        end
        let(:notification) do
          create(:notification,
                 reason: :date_alert_start_date,
                 recipient:,
                 resource: work_package)
        end

        it "matches generated text" do
          expect(mail_body).to have_text("Start date is in 2 days")
        end
      end

      context "when notification_wp_due_past" do
        let(:work_package) do
          create(:work_package, subject: "WP due past", project: project1, due_date: 3.days.ago, type: Type.first)
        end
        let(:notification) do
          create(:notification,
                 reason: :date_alert_due_date,
                 recipient:,
                 resource: work_package)
        end

        it "matches generated text" do
          expect(mail_body).to have_text("Overdue since 3 days")
        end
      end

      context "when notification_wp_due_future" do
        let(:work_package) do
          create(:work_package, subject: "WP due future", project: project1, due_date: 3.days.from_now, type: Type.first)
        end
        let(:notification) do
          create(:notification,
                 reason: :date_alert_due_date,
                 recipient:,
                 resource: work_package)
        end

        it "matches generated text" do
          expect(mail_body).to have_text("Finish date is in 3 days")
        end
      end

      context "when notification_milestone_past" do
        let(:milestone_type) { create(:type_milestone) }
        let(:work_package) do
          create(:work_package, subject: "Milestone WP past", project: project1, type: milestone_type, due_date: 2.days.ago)
        end
        let(:notification) do
          create(:notification,
                 reason: :date_alert_due_date,
                 recipient:,
                 resource: work_package)
        end

        it "matches generated text" do
          expect(mail_body).to include('<span style="color: #C92A2A">Overdue since 2 days</span>')
        end
      end

      context "when notification_milestone_future" do
        let(:milestone_type) { create(:type_milestone) }
        let(:work_package) do
          create(:work_package, subject: "Milestone WP future", project: project1, type: milestone_type, due_date: 1.day.from_now)
        end
        let(:notification) do
          create(:notification,
                 reason: :date_alert_due_date,
                 recipient:,
                 resource: work_package)
        end

        it "matches generated text" do
          expect(mail_body).to have_text("Milestone date is in 1 day")
        end
      end

      context "when notification_wp_unset_date" do
        let(:work_package) { create(:work_package, subject: "Unset date", project: project1, due_date: nil, type: Type.first) }
        let(:notification) do
          create(:notification,
                 reason: :date_alert_due_date,
                 recipient:,
                 resource: work_package)
        end

        it "matches generated text" do
          expect(mail_body).to have_text("Finish date is deleted")
        end
      end

      context "when notification_wp_due_today" do
        let(:work_package) do
          create(:work_package, subject: "Due today", project: project1, due_date: Time.zone.today, type: Type.first)
        end
        let(:notification) do
          create(:notification,
                 reason: :date_alert_due_date,
                 recipient:,
                 resource: work_package)
        end

        it "matches generated text" do
          expect(mail_body).to have_text("Finish date is today")
        end
      end

      context "when notification_wp_double_date_alert" do
        let(:work_package) do
          create(:work_package, subject: "Alert + Mention", project: project1, due_date: 1.day.from_now, type: Type.first)
        end
        let(:notification) do
          create(:notification,
                 reason: :date_alert_due_date,
                 recipient:,
                 resource: work_package)
        end

        it "matches generated text" do
          expect(mail_body).to have_text("Finish date is in 1 day")
        end
      end

      context "when notification is mentioned and no journal" do
        let(:work_package) { create(:work_package, subject: "Unset date", project: project1, due_date: nil, type: Type.first) }
        let(:notification) do
          create(:notification,
                 reason: :mentioned,
                 recipient:,
                 resource: work_package,
                 journal: nil)
        end

        it "does not send the email" do
          expect(mail.body).to eq("")
        end
      end
    end
  end
end
