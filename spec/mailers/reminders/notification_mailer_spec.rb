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

RSpec.describe Reminders::NotificationMailer do
  let(:work_package) { build_stubbed(:work_package) }
  let(:user) { build_stubbed(:user) }
  let(:recipient) { user }

  let(:notification) do
    reminder = build_stubbed(:reminder, remindable: work_package, creator: user, note: "This is an important reminder")
    build_stubbed(:notification, reason: :reminder, recipient:, resource: work_package, reminder:)
  end

  describe "#reminder_notification" do
    subject(:mail) { described_class.reminder_notification(notification) }

    let(:mail_body) { mail.body.parts.detect { |part| part["Content-Type"].value == "text/html" }.body.to_s }

    describe "Email subject" do
      context "when the reminder has a note" do
        it "includes the note" do
          expect(mail.subject).to eql("OpenProject - Reminder: This is an important reminder")
        end
      end

      context "when the reminder does not have a note" do
        before do
          notification.reminder.note = ""
        end

        it "includes the work package subject" do
          expect(mail.subject).to eql("OpenProject - Reminder: #{work_package.subject}")
        end
      end
    end

    it "sends to the recipient" do
      expect(mail.to)
        .to contain_exactly(recipient.mail)
    end

    it "sets the expected message_id header" do
      expect(mail.message_id)
        .to eql "op.reminder.#{Time.current.strftime('%Y%m%d%H%M%S')}.#{recipient.id}@example.net"
    end

    it "sets the expected openproject headers" do
      expect(mail["X-OpenProject-User"]&.value)
        .to eql(recipient.name)
    end

    it "mail body includes the reminder note" do
      expect(mail_body).to include("Note: “This is an important reminder”")
    end

    context "with classic mode", with_settings: { work_packages_identifier: "classic" } do
      it "shows the # prefixed numeric id in the mail body" do
        expect(mail_body).to include("##{work_package.id}")
      end
    end

    context "with semantic mode",
            with_settings: { work_packages_identifier: "semantic" } do
      let(:work_package) do
        build_stubbed(:work_package, identifier: "PROJ-42", sequence_number: 42)
      end

      it "shows the semantic identifier without # prefix in the mail body" do
        expect(mail_body).to include("PROJ-42")
        expect(mail_body).not_to include("#PROJ-42")
      end
    end
  end
end
