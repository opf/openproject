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
require_module_spec_helper

RSpec.describe ITSM::EmailThread do
  subject(:thread) { build(:itsm_email_thread, work_package:, requester_email:, recipients:) }

  let(:work_package) { create(:work_package) }
  let(:requester_email) { "Requester@Customer.example" }
  let(:recipients) { [] }

  it { is_expected.to be_valid }

  it "normalizes the requester email" do
    expect(thread.requester_email).to eq("requester@customer.example")
  end

  context "with recipients" do
    let(:recipients) { [" Jane@Customer.example", "", "jane@customer.example", "bob@customer.example"] }

    it "normalizes them" do
      expect(thread.recipients).to eq(%w[jane@customer.example bob@customer.example])
    end
  end

  context "without a work package" do
    let(:work_package) { nil }

    it { is_expected.not_to be_valid }
  end

  context "when the work package already has a thread" do
    let!(:existing) { create(:itsm_email_thread, work_package:) }

    it { is_expected.not_to be_valid }
  end

  describe "#sent_confirmation" do
    let(:thread) { create(:itsm_email_thread, work_package:) }
    let!(:failed) { create(:itsm_email_message, thread:, direction: "outbound", status: "failed") }

    it "is nothing while no outbound email was sent" do
      expect(thread.sent_confirmation).to be_nil
    end

    context "with sent outbound emails" do
      let!(:first_sent) { create(:itsm_email_message, thread:, direction: "outbound", status: "sent") }
      let!(:second_sent) { create(:itsm_email_message, thread:, direction: "outbound", status: "sent") }

      it "is the first one" do
        expect(thread.sent_confirmation).to eq(first_sent)
      end
    end

    context "with a comment sent as a reply" do
      let(:journal) { create(:work_package_journal, journable: work_package, version: 2) }

      before { create(:itsm_email_message, thread:, journal:, direction: "outbound", status: "sent") }

      it "is nothing" do
        expect(thread.sent_confirmation).to be_nil
      end
    end
  end

  describe "#unsent_confirmation" do
    let(:thread) { create(:itsm_email_thread, work_package:) }
    let!(:sent) { create(:itsm_email_message, thread:, direction: "outbound", status: "sent") }

    it "is a new outbound email of the thread" do
      expect(thread.unsent_confirmation).to be_new_record.and have_attributes(thread:, direction: "outbound")
    end

    context "with an outbound email that was not sent" do
      let!(:failed) { create(:itsm_email_message, thread:, direction: "outbound", status: "failed") }

      it "is that email" do
        expect(thread.unsent_confirmation).to eq(failed)
      end
    end

    context "with a reply that was not sent" do
      let(:journal) { create(:work_package_journal, journable: work_package, version: 2) }

      before { create(:itsm_email_message, thread:, journal:, direction: "outbound", status: "failed") }

      it "is a new outbound email of the thread" do
        expect(thread.unsent_confirmation).to be_new_record
      end
    end
  end

  describe "#sent_reply" do
    let(:thread) { create(:itsm_email_thread, work_package:) }
    let(:journal) { create(:work_package_journal, journable: work_package, version: 2) }
    let!(:failed) { create(:itsm_email_message, thread:, journal:, direction: "outbound", status: "failed") }

    it "is nothing while the comment was not sent" do
      expect(thread.sent_reply(journal)).to be_nil
    end

    context "when the comment was sent" do
      let!(:sent) { create(:itsm_email_message, thread:, journal:, direction: "outbound", status: "sent") }

      it "is that email" do
        expect(thread.sent_reply(journal)).to eq(sent)
      end
    end
  end

  describe "#unsent_reply" do
    let(:thread) { create(:itsm_email_thread, work_package:) }
    let(:journal) { create(:work_package_journal, journable: work_package, version: 2) }

    before { create(:itsm_email_message, thread:, direction: "outbound", status: "failed") }

    it "is a new outbound email for the comment" do
      expect(thread.unsent_reply(journal)).to be_new_record.and have_attributes(thread:, journal:, direction: "outbound")
    end

    context "with an email for the comment that was not sent" do
      let!(:failed) { create(:itsm_email_message, thread:, journal:, direction: "outbound", status: "failed") }

      it "is that email" do
        expect(thread.unsent_reply(journal)).to eq(failed)
      end
    end
  end

  describe "#inbound_message_ids" do
    let(:thread) { create(:itsm_email_thread, work_package:) }

    before do
      create(:itsm_email_message, thread:, message_id: "second@customer.example", created_at: 1.hour.ago)
      create(:itsm_email_message, thread:, message_id: "first@customer.example", created_at: 2.hours.ago)
      create(:itsm_email_message, thread:, direction: "outbound", status: "sent", message_id: "ours@example.com")
    end

    it "lists the Message-IDs of the received emails, oldest first" do
      expect(thread.inbound_message_ids).to eq(%w[first@customer.example second@customer.example])
    end
  end

  context "when its work package is deleted" do
    let!(:saved_thread) { create(:itsm_email_thread, work_package:) }
    let!(:message) { create(:itsm_email_message, thread: saved_thread) }

    it "is deleted together with its messages" do
      work_package.destroy

      expect(described_class).not_to exist(saved_thread.id)
      expect(ITSM::EmailMessage).not_to exist(message.id)
    end
  end
end
