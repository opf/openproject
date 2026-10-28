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

RSpec.describe ITSM::Mailboxes::FetchJob, type: :job, with_flag: { helpdesk: true } do
  subject(:perform) { described_class.perform_now(mailbox) }

  let(:mailbox) { create(:itsm_incoming_mailbox) }
  let(:emails_left) { false }
  let(:service) do
    instance_double(ITSM::Mailboxes::FetchService,
                    call: ServiceResult.success(result: mailbox, state: Shared::ServiceState.build(emails_left:)))
  end

  before { allow(ITSM::Mailboxes::FetchService).to receive(:new).with(model: mailbox).and_return(service) }

  it "fetches the mailbox once" do
    perform

    expect(service).to have_received(:call)
    expect(described_class).not_to have_been_enqueued
  end

  context "when emails are left on the server", :freeze_time do
    let(:emails_left) { true }

    it "queues the next fetch a minute later" do
      perform

      expect(described_class).to have_been_enqueued.with(mailbox).at(1.minute.from_now)
    end
  end

  context "when the fetch fails" do
    let(:service) { instance_double(ITSM::Mailboxes::FetchService, call: ServiceResult.failure(result: mailbox)) }

    it "leaves the retry to the schedule" do
      perform

      expect(described_class).not_to have_been_enqueued
    end
  end

  context "when the mailbox was deleted before the job ran" do
    before do
      described_class.perform_later(mailbox)
      mailbox.destroy
    end

    it "drops the job" do
      expect { perform_enqueued_jobs }.not_to raise_error
      expect(ITSM::Mailboxes::FetchService).not_to have_received(:new)
    end
  end

  context "when the mailbox is already queued", with_good_job_batches: [described_class] do
    let(:other_mailbox) { create(:itsm_incoming_mailbox) }

    before { described_class.perform_later(mailbox) }

    it "does not queue it a second time" do
      expect(described_class.perform_later(mailbox)).to be(false)
      expect(described_class.perform_later(other_mailbox).successfully_enqueued?).to be(true)
    end
  end
end
