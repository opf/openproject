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

RSpec.describe Notifications::MailService, type: :model do
  require_relative "mentioned_journals_shared"

  subject(:call) { instance.call }

  let(:recipient) do
    build_stubbed(:user,
                  preferences: {
                    immediate_reminders: {
                      mentioned: immediate_reminders_mentioned
                    }
                  })
  end
  let(:actor) do
    build_stubbed(:user)
  end
  let(:instance) { described_class.new(notification) }
  let(:immediate_reminders_mentioned) { true }

  context "with a work package journal notification" do
    let(:journal) do
      build_stubbed(:work_package_journal).tap do |j|
        allow(j)
          .to receive(:initial?)
                .and_return(journal_initial)
      end
    end
    let(:read_ian) { false }
    let(:reason) { :mentioned }
    let(:notification) do
      build_stubbed(:notification,
                    journal:,
                    recipient:,
                    actor:,
                    reason:,
                    read_ian:)
    end
    let(:journal_initial) { false }

    let(:mail) do
      mail = instance_double(ActionMailer::MessageDelivery)

      allow(WorkPackageMailer)
        .to receive(:mentioned)
              .and_return(mail)

      allow(mail)
        .to receive(:deliver_later)

      mail
    end

    before do
      mail
    end

    shared_examples_for "sends a mentioned mail" do
      it "sends a mail" do
        call

        expect(WorkPackageMailer)
          .to have_received(:mentioned)
                .with(recipient,
                      journal)

        expect(mail)
          .to have_received(:deliver_later)
      end
    end

    shared_examples_for "sends no mentioned mail" do
      it "sends no mail" do
        call

        expect(WorkPackageMailer)
          .not_to have_received(:mentioned)
      end
    end

    context "with the notification mentioning the user" do
      it_behaves_like "sends a mentioned mail"
    end

    context "with the notification not mentioning the user" do
      let(:reason) { false }

      it_behaves_like "sends no mentioned mail"
    end

    context "with the notification mentioning the user but with the recipient having deactivated the mail" do
      let(:immediate_reminders_mentioned) { false }

      it_behaves_like "sends no mentioned mail"
    end
  end

  context "with a wiki_content journal notification" do
    let(:journal) do
      build_stubbed(:wiki_page_journal,
                    journable: build_stubbed(:wiki_page)).tap do |j|
        allow(j)
          .to receive(:initial?)
                .and_return(journal_initial)
      end
    end
    let(:read_ian) { false }
    let(:notification) do
      build_stubbed(:notification,
                    journal:,
                    recipient:,
                    actor:,
                    read_ian:)
    end
    let(:mail) do
      mail = instance_double(ActionMailer::MessageDelivery)

      allow(UserMailer)
        .to receive(:wiki_page_added)
              .and_return(mail)

      allow(UserMailer)
        .to receive(:wiki_page_updated)
              .and_return(mail)

      allow(mail)
        .to receive(:deliver_now)

      mail
    end
    let(:journal_initial) { false }

    before do
      mail
    end

    context "with the notification being for an initial journal" do
      let(:journal_initial) { true }

      it "sends a mail" do
        call

        expect(UserMailer)
          .to have_received(:wiki_page_added)
                .with(recipient,
                      journal.journable)

        expect(mail)
          .to have_received(:deliver_now)
      end
    end

    context "with the notification being for an update journal" do
      let(:journal_initial) { false }

      it "sends a mail" do
        call

        expect(UserMailer)
          .to have_received(:wiki_page_updated)
                .with(recipient,
                      journal.journable)

        expect(mail)
          .to have_received(:deliver_now)
      end
    end

    context "with the notification read in app already" do
      let(:read_ian) { true }

      it "sends no mail" do
        call

        expect(UserMailer)
          .not_to have_received(:wiki_page_added)
        expect(UserMailer)
          .not_to have_received(:wiki_page_updated)
      end
    end
  end

  context "with a news journal notification" do
    let(:journal) do
      build_stubbed(:news_journal,
                    journable: build_stubbed(:news)).tap do |j|
        allow(j)
          .to receive(:initial?)
                .and_return(journal_initial)
      end
    end
    let(:notification) do
      build_stubbed(:notification,
                    journal:,
                    recipient:,
                    actor:)
    end
    let(:mail) do
      mail = instance_double(ActionMailer::MessageDelivery)

      allow(UserMailer)
        .to receive(:news_added)
              .and_return(mail)

      allow(mail)
        .to receive(:deliver_now)

      mail
    end
    let(:journal_initial) { false }

    before do
      mail
    end

    context "with the notification being for an initial journal" do
      let(:journal_initial) { true }

      it "sends a mail" do
        call

        expect(UserMailer)
          .to have_received(:news_added)
                .with(recipient,
                      journal.journable)

        expect(mail)
          .to have_received(:deliver_now)
      end
    end

    # This case should not happen as no notification is created in this case that would
    # trigger the NotificationJob. But as this might change, this test case is in place.
    context "with the notification being for an update journal" do
      let(:journal_initial) { false }

      it "sends no mail" do
        call

        expect(UserMailer)
          .not_to have_received(:news_added)
      end
    end
  end

  context "with a message journal notification" do
    let(:journal) do
      build_stubbed(:message_journal,
                    journable: build_stubbed(:message))
    end
    let(:read_ian) { false }
    let(:notification) do
      build_stubbed(:notification,
                    journal:,
                    resource: journal.journable,
                    recipient:,
                    actor:,
                    read_ian:)
    end
    let(:mail) do
      mail = instance_double(ActionMailer::MessageDelivery)

      allow(UserMailer)
        .to receive(:message_posted)
              .and_return(mail)

      allow(mail)
        .to receive(:deliver_now)

      mail
    end

    before do
      mail
    end

    it "sends a mail" do
      call

      expect(UserMailer)
        .to have_received(:message_posted)
              .with(recipient,
                    journal.journable)

      expect(mail)
        .to have_received(:deliver_now)
    end

    context "with the notification read in app already" do
      let(:read_ian) { true }

      it "sends no mail" do
        call

        expect(UserMailer)
          .not_to have_received(:message_posted)
      end
    end
  end

  context "with a different journal notification" do
    let(:journal) do
      build_stubbed(:journal,
                    journable: build_stubbed(:work_package))
    end
    let(:notification) do
      build_stubbed(:notification,
                    journal:,
                    recipient:,
                    actor:)
    end

    # did that before
    it "does nothing" do
      expect { call }
        .not_to raise_error(ArgumentError)
    end

    it "does not send a mail" do
      expect { call }
        .not_to change(ActionMailer::Base.deliveries, :count)
    end
  end
end
