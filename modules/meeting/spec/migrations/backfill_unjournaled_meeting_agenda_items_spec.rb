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
require Rails.root.join("modules/meeting/db/migrate/20261010090000_backfill_unjournaled_meeting_agenda_items.rb")

RSpec.describe BackfillUnjournaledMeetingAgendaItems, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:up) } }

  # Journal 1: the meeting is created. Journal 2: its backlog is journaled.
  shared_let(:meeting) { travel_to(3.hours.ago) { create(:meeting) } }

  before_all do
    travel_to(170.minutes.ago) { meeting.touch_and_save_journals }
  end

  # Created while journal 2 was the current one, but never journaled.
  shared_let(:unjournaled_item) do
    travel_to(150.minutes.ago) { create(:meeting_agenda_item, meeting:, title: "Never journaled") }
  end

  # Journal 3: an agenda item is added and journaled.
  shared_let(:journaled_item) { travel_to(2.hours.ago) { create(:meeting_agenda_item, meeting:) } }

  before_all do
    travel_to(2.hours.ago) { meeting.touch_and_save_journals }
  end

  # Journal 4: the journaled item is changed.
  before_all do
    travel_to(1.hour.ago) do
      journaled_item.update!(title: "Changed")
      meeting.touch_and_save_journals
    end
  end

  before do
    # Journaling above recorded the unjournaled item as well, and the journaled item in all journals since its creation.
    # Remove those rows to simulate an item that was never journaled and one that is missing from a single journal.
    Journal::MeetingAgendaItemJournal.where(agenda_item_id: unjournaled_item.id).delete_all
    Journal::MeetingAgendaItemJournal.where(agenda_item_id: journaled_item.id, journal_id: journals.last.id).delete_all
  end

  def journals = meeting.journals.order(:version).to_a

  def journaled_item_ids = journals.map { it.agenda_item_journals.pluck(:agenda_item_id) }

  it "adds a never journaled agenda item to every journal that was valid when it was created" do
    migrate

    expect(journaled_item_ids)
      .to match([
                  be_empty,
                  contain_exactly(unjournaled_item.id),
                  contain_exactly(unjournaled_item.id, journaled_item.id),
                  contain_exactly(unjournaled_item.id)
                ])
  end

  it "copies the current values of the agenda item" do
    migrate

    expect(journals.last.agenda_item_journals.find_by(agenda_item_id: unjournaled_item.id))
      .to have_attributes(title: "Never journaled", author_id: unjournaled_item.author_id,
                          position: unjournaled_item.position)
  end
end
