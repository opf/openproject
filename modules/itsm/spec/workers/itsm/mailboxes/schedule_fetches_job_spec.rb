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

RSpec.describe ITSM::Mailboxes::ScheduleFetchesJob, type: :job, with_flag: { helpdesk: true } do
  let!(:due) { create(:itsm_incoming_mailbox, next_fetch_at: 1.minute.ago) }
  let!(:not_yet_due) { create(:itsm_incoming_mailbox, next_fetch_at: 1.minute.from_now) }

  it "queues a fetch for every mailbox that is due" do
    described_class.perform_now

    expect(ITSM::Mailboxes::FetchJob).to have_been_enqueued.with(due).once
    expect(ITSM::Mailboxes::FetchJob).not_to have_been_enqueued.with(not_yet_due)
  end

  context "with the help desk feature disabled", with_flag: { helpdesk: false } do
    it "queues nothing" do
      expect { described_class.perform_now }.not_to have_enqueued_job(ITSM::Mailboxes::FetchJob)
    end
  end
end
