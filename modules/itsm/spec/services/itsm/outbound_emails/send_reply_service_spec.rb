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

RSpec.describe ITSM::OutboundEmails::SendReplyService do
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:journal) { create(:work_package_journal, journable: work_package, notes: "We fixed it.", version: 2) }
  let!(:thread) do
    create(:itsm_email_thread, work_package:, requester_email: "jane@customer.example", recipients: ["joe@customer.example"])
  end
  let!(:mailbox) { create(:itsm_outgoing_mailbox, project:, sender_email: "support@helpdesk.example", sender_name: "Support") }

  subject(:result) { described_class.new(journal:).call }

  it "records a queued reply to the requester and all recipients for the comment" do
    expect(result).to be_success
    expect(result.result).to have_attributes(
      thread:,
      journal:,
      direction: "outbound",
      status: "queued",
      from_address: "support@helpdesk.example",
      from_name: "Support",
      to_addresses: ["jane@customer.example"],
      cc_addresses: ["joe@customer.example"],
      message_id: a_string_ending_with("@helpdesk.example")
    )
  end

  it "sends no email" do
    expect { result }.not_to change(ActionMailer::Base.deliveries, :count)
  end
end
