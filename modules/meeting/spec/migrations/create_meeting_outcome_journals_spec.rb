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
require Rails.root.join("modules/meeting/db/migrate/20261012100000_create_meeting_outcome_journals.rb")

RSpec.describe CreateMeetingOutcomeJournals, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:up) } }

  def meeting_created_at = Time.zone.local(2026, 1, 1, 9)
  def first_item_journaled_at = Time.zone.local(2026, 1, 1, 9, 10)
  def other_meeting_outcome_recorded_at = Time.zone.local(2026, 1, 1, 9, 30)
  def first_outcome_recorded_at = Time.zone.local(2026, 1, 1, 10)
  def item_moved_at = Time.zone.local(2026, 1, 1, 11)

  # Journal 1: the meeting is created. Journal 2: only the first agenda item exists.
  shared_let(:meeting) { travel_to(meeting_created_at) { create(:meeting) } }
  shared_let(:first_item) { travel_to(meeting_created_at) { create(:meeting_agenda_item, meeting:) } }

  before_all do
    travel_to(first_item_journaled_at) { meeting.touch_and_save_journals }
  end

  # Not yet part of the meeting: its outcome exists before journal 3 but its agenda item only joins in journal 4.
  shared_let(:other_meeting) { create(:meeting) }
  shared_let(:moved_item) do
    travel_to(other_meeting_outcome_recorded_at) { create(:meeting_agenda_item, meeting: other_meeting) }
  end
  shared_let(:moved_item_outcome) do
    travel_to(other_meeting_outcome_recorded_at) do
      create(:meeting_outcome, meeting_agenda_item: moved_item, notes: "Moved along")
    end
  end

  # Journal 3: an outcome is recorded for the first agenda item.
  shared_let(:first_outcome) do
    travel_to(first_outcome_recorded_at) { create(:meeting_outcome, meeting_agenda_item: first_item, notes: "Agreed") }
  end

  before_all do
    travel_to(first_outcome_recorded_at) { meeting.touch_and_save_journals }
  end

  # Journal 4: the other agenda item is moved into the meeting.
  before_all do
    travel_to(item_moved_at) do
      moved_item.update!(meeting:, meeting_section: meeting.sections.first || meeting.own_backlog)
      meeting.touch_and_save_journals
    end
  end

  before do
    # The test schema already contains the table and journaling above filled it,
    # so remove it to simulate the state the backfill runs against.
    ActiveRecord::Base.connection.drop_table(:meeting_outcome_journals)
  end

  def journals = meeting.journals.order(:version).to_a

  it "records in each journal the outcomes that existed by then and whose agenda item it records" do
    migrate

    expect(journals.map { it.outcome_journals.pluck(:outcome_id) })
      .to match([
                  be_empty,
                  be_empty,
                  contain_exactly(first_outcome.id),
                  contain_exactly(first_outcome.id, moved_item_outcome.id)
                ])
  end

  it "copies the current values of the outcomes" do
    migrate

    expect(journals.last.outcome_journals.find_by(outcome_id: first_outcome.id))
      .to have_attributes(meeting_agenda_item_id: first_item.id, work_package_id: nil,
                          kind: MeetingOutcome.kinds[:information], notes: "Agreed")
  end

  it "leaves the latest journal matching the current state, so the next save creates no journal" do
    migrate

    expect { meeting.save_journals }.not_to change(Journal, :count)
  end

  context "for outcomes created while the journal was the current one" do
    shared_let(:later_outcome) { create(:meeting_outcome, meeting_agenda_item: first_item, notes: "Follow-up") }

    it "records the outcomes in that journal" do
      migrate

      expect(journals.last.outcome_journals.pluck(:outcome_id))
        .to contain_exactly(first_outcome.id, moved_item_outcome.id, later_outcome.id)
    end
  end
end
