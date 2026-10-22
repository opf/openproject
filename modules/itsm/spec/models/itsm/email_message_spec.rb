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

RSpec.describe ITSM::EmailMessage do
  subject(:message) { build(:itsm_email_message, mailbox:, message_id:, direction:) }

  let(:mailbox) { create(:itsm_mailbox) }
  let(:message_id) { "abc@customer.example" }
  let(:direction) { "inbound" }

  it { is_expected.to be_valid }

  context "with an unknown direction" do
    let(:direction) { "sideways" }

    it { is_expected.not_to be_valid }
  end

  context "without a mailbox" do
    let(:mailbox) { nil }

    it { is_expected.not_to be_valid }
  end

  context "when an inbound message has no thread" do
    subject(:message) { build(:itsm_email_message, direction: "inbound", thread: nil) }

    it { is_expected.to be_valid }
  end

  context "when an outbound message has no thread" do
    subject(:message) { build(:itsm_email_message, direction: "outbound", thread: nil) }

    it { is_expected.not_to be_valid }
  end

  context "when the mailbox already received the message" do
    let!(:existing) { create(:itsm_email_message, mailbox:, message_id:) }

    it { is_expected.not_to be_valid }
  end

  context "when another mailbox received the same message" do
    let!(:existing) { create(:itsm_email_message, message_id:) }

    it { is_expected.to be_valid }
  end

  context "when the mailboxes of both messages were deleted" do
    subject(:message) { create(:itsm_email_message, message_id:) }

    let!(:existing) { create(:itsm_email_message, message_id:) }

    it "can still be saved" do
      existing.mailbox.destroy
      message.mailbox.destroy

      expect(message.reload).to be_valid
    end
  end
end
