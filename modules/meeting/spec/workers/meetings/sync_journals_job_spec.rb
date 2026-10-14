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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Meetings::SyncJournalsJob, type: :model, with_settings: { journal_aggregation_time_minutes: 0 } do
  shared_let(:synced_meeting) { create(:meeting) }
  shared_let(:unsynced_meeting) { create(:meeting) }
  shared_let(:unjournaled_section) { create(:meeting_section, meeting: unsynced_meeting, title: "Not journaled") }

  subject(:perform) { described_class.new.perform }

  before do
    synced_meeting.save_journals
  end

  it "journals a meeting out of sync with its latest journal as the system user" do
    expect { perform }.to change { unsynced_meeting.journals.count }.by(1)

    expect(unsynced_meeting.last_journal)
      .to have_attributes(user: User.system, cause_type: "system_update", cause_feature: "meeting_journal_sync")
    expect(unsynced_meeting.last_journal.section_journals.pluck(:section_id)).to include(unjournaled_section.id)
  end

  it "does not journal a meeting in sync with its latest journal" do
    expect { perform }.not_to change { synced_meeting.journals.count }
  end

  it "does not journal a meeting again on a second run" do
    perform

    expect { described_class.new.perform }.not_to change(Journal, :count)
  end

  it "suppresses journal notifications" do
    allow(Journal::NotificationConfiguration).to receive(:with).and_call_original

    perform

    expect(Journal::NotificationConfiguration).to have_received(:with).with(false)
  end
end
