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

RSpec.describe ITSM::OutboundEmails::ReplyChannel do
  let(:work_package) { create(:work_package) }
  let(:user) { build_stubbed(:user) }
  let(:journal) { create(:work_package_journal, journable: work_package, notes: "We fixed it.", version: 2) }
  let(:thread) { create(:itsm_email_thread, work_package:) }

  subject(:channel) { described_class.new }

  it "is registered as a comment channel" do
    expect(WorkPackages::CommentChannels.find("email_reply")).to be_a(described_class)
  end

  it "describes itself for the comment editor and the activity" do
    expect(channel).to have_attributes(
      key: "email_reply",
      label: "Reply to recipients",
      delivered_label: "Sent to the recipients by email",
      icon: :"op-mail-sent",
      journal_preloads: [:helpdesk_reply]
    )
  end

  describe "#available?" do
    let(:availability) { instance_double(ITSM::OutboundEmails::ReplyAvailability, available?: true) }

    before do
      allow(ITSM::OutboundEmails::ReplyAvailability).to receive(:new).with(work_package:, user:).and_return(availability)
    end

    it "asks the reply availability" do
      expect(channel.available?(work_package:, user:)).to be(true)
    end
  end

  describe "#deliver" do
    let(:send_service) { instance_double(ITSM::OutboundEmails::SendReplyService, call: ServiceResult.success) }

    before do
      allow(ITSM::OutboundEmails::SendReplyService).to receive(:new).with(journal:).and_return(send_service)
    end

    it "sends the comment as a reply" do
      channel.deliver(journal)

      expect(send_service).to have_received(:call)
    end
  end

  describe "#delivered?" do
    subject { channel.delivered?(journal) }

    it { is_expected.to be(false) }

    context "with an outbound email for the comment" do
      before { create(:itsm_email_message, thread:, journal:, direction: "outbound", status: "queued") }

      it { is_expected.to be(true) }
    end

    context "with an inbound email for the comment" do
      before { create(:itsm_email_message, thread:, journal:) }

      it { is_expected.to be(false) }
    end
  end
end
