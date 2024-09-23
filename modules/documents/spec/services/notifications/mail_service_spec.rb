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
  subject(:call) { instance.call }

  let(:recipient) do
    build_stubbed(:user)
  end
  let(:actor) do
    build_stubbed(:user)
  end
  let(:instance) { described_class.new(notification) }

  context "with a document journal notification" do
    let(:journal) do
      build_stubbed(:journal,
                    journable: build_stubbed(:document)).tap do |j|
        allow(j)
          .to receive(:initial?)
                .and_return(initial_journal)
      end
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
    let(:notification_setting) { %w(document_added) }
    let(:mail) do
      mail = instance_double(ActionMailer::MessageDelivery)

      allow(DocumentsMailer)
        .to receive(:document_added)
              .and_return(mail)

      allow(mail)
        .to receive(:deliver_later)

      mail
    end
    let(:initial_journal) { true }

    before do
      mail
    end

    it "sends a mail" do
      call

      expect(DocumentsMailer)
        .to have_received(:document_added)
              .with(recipient,
                    journal.journable)

      expect(mail)
        .to have_received(:deliver_later)
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
end
