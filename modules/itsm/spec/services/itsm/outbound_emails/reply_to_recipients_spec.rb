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

RSpec.describe "Replying to the recipients of a help desk request", # rubocop:disable RSpec/DescribeClass
               with_flag: { helpdesk: true },
               with_settings: { helpdesk_enabled: true } do
  subject(:add_comment) do
    WorkPackages::ActivitiesTab::CommentService
      .new(work_package:, user:, params: ActionController::Parameters.new(journal: { notes: "We replaced the toner.", mode: }))
      .add
  end

  let(:mode) { "email_reply" }
  let(:project) { create(:project, enabled_module_names: %i[work_package_tracking helpdesk]) }
  let(:work_package) { create(:work_package, project:, subject: "Printer is broken") }
  let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages add_work_package_comments] }) }
  let(:thread) { create(:itsm_email_thread, work_package:, recipients: ["colleague@customer.example"]) }
  let(:delivered) { ActionMailer::Base.deliveries.last }

  before do
    create(:itsm_email_message, thread:, message_id: "request@customer.example")
    create(:itsm_outgoing_mailbox, project:, sender_email: "support@example.com")
    with_ssrf_ip_allowlist(%w[203.0.113.10])
    allow(OpenProject::SsrfProtection).to receive(:resolver).and_return(->(_host) { [IPAddr.new("203.0.113.10")] })
    allow(ITSM::HelpdeskMailer).to receive(:mailbox_delivery_method).and_return(:test)
  end

  it "saves the comment and emails it to the requester and the recipients" do
    journal = perform_enqueued_jobs { add_comment }.result

    expect(journal.notes).to eq("We replaced the toner.")
    expect(delivered).to have_attributes(to: ["requester@customer.example"],
                                         cc: ["colleague@customer.example"],
                                         in_reply_to: "request@customer.example")
    expect(delivered.body.encoded).to include("We replaced the toner.")
    expect(WorkPackages::CommentChannels.delivering(journal)).to be_a(ITSM::OutboundEmails::ReplyChannel)
  end

  context "with a public comment" do
    let(:mode) { "public" }

    it "emails nothing" do
      journal = perform_enqueued_jobs { add_comment }.result

      expect(ActionMailer::Base.deliveries.select { it.to.include?("requester@customer.example") }).to be_empty
      expect(WorkPackages::CommentChannels.delivering(journal)).to be_nil
    end
  end

  context "when the work package was not created from an email" do
    let(:thread) { create(:itsm_email_thread, work_package: create(:work_package, project:)) }

    it "saves nothing and says why" do
      expect { add_comment }.not_to change(work_package.journals, :count)
      expect(add_comment.errors.full_messages).to eq(["Reply to recipients is not available for this work package."])
    end
  end
end
