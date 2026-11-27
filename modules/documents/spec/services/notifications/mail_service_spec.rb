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

RSpec.describe Notifications::MailService, type: :model do
  subject(:call) { instance.call }

  let(:recipient) do
    build_stubbed(:user,
                  preferences: {
                    immediate_reminders: {
                      mentioned: immediate_reminders_mentioned
                    }
                  })
  end
  let(:immediate_reminders_mentioned) { true }
  let(:actor) do
    build_stubbed(:user)
  end
  let(:instance) { described_class.new(notification) }
  let(:read_ian) { nil }
  let(:mail) do
    mail = instance_double(ActionMailer::MessageDelivery)

    allow(DocumentsMailer)
      .to receive_messages(document_added: mail, mentioned: mail)

    allow(mail)
      .to receive(:deliver_later)

    mail
  end

  before do
    mail
  end

  context "with a document journal notification" do
    let(:journal) do
      build_stubbed(:journal,
                    journable: build_stubbed(:document)).tap do |j|
        allow(j)
          .to receive(:initial?)
                .and_return(initial_journal)
      end
    end
    let(:notification) do
      build_stubbed(:notification,
                    journal:,
                    reason: :subscribed,
                    resource: journal.journable,
                    recipient:,
                    actor:,
                    read_ian:)
    end
    let(:initial_journal) { true }

    it "sends a document added mail" do
      call

      expect(DocumentsMailer)
        .to have_received(:document_added)
              .with(recipient,
                    journal.journable)

      expect(mail)
        .to have_received(:deliver_later)

      expect(DocumentsMailer)
        .not_to have_received(:mentioned)
    end

    context "with the notification read in app already" do
      let(:read_ian) { true }

      it "sends no mail" do
        call

        expect(DocumentsMailer)
          .not_to have_received(:document_added)
      end
    end

    context "with the journal not being the initial one" do
      let(:initial_journal) { false }

      it "sends no mail" do
        call

        expect(DocumentsMailer)
          .not_to have_received(:document_added)
      end
    end
  end

  context "with a mention notification without a journal" do
    let(:document) { build_stubbed(:document) }
    let(:notification) do
      build_stubbed(:notification,
                    journal: nil,
                    reason: :mentioned,
                    resource: document,
                    recipient:,
                    actor:,
                    read_ian:)
    end

    it "sends a mentioned mail" do
      call

      expect(DocumentsMailer)
        .to have_received(:mentioned)
              .with(recipient, notification)

      expect(mail)
        .to have_received(:deliver_later)

      expect(DocumentsMailer)
        .not_to have_received(:document_added)
    end

    context "with the recipient having deactivated immediate mails for mentions" do
      let(:immediate_reminders_mentioned) { false }

      it "sends no mail" do
        call

        expect(DocumentsMailer)
          .not_to have_received(:mentioned)
        expect(DocumentsMailer)
          .not_to have_received(:document_added)
      end
    end
  end
end
