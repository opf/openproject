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
require Rails.root.join("modules/meeting/db/migrate/20261010100000_create_meeting_section_journals.rb")

RSpec.describe CreateMeetingSectionJournals, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:up) } }

  shared_let(:presenter) { create(:user) }

  # Journal 1: only the backlog exists.
  shared_let(:meeting) { travel_to(3.hours.ago) { create(:meeting) } }

  # Journal 2: the first section and an agenda item in it are added.
  shared_let(:first_section) { travel_to(2.hours.ago) { create(:meeting_section, meeting:, title: "Discussion") } }
  shared_let(:agenda_item) do
    travel_to(2.hours.ago) { create(:meeting_agenda_item, meeting:, meeting_section: first_section, presenter:) }
  end

  before_all do
    travel_to(2.hours.ago) { meeting.touch_and_save_journals }
  end

  # Journal 3: a second section is added and the agenda item moved into it.
  shared_let(:second_section) { travel_to(1.hour.ago) { create(:meeting_section, meeting:, title: "Decisions") } }

  before_all do
    travel_to(1.hour.ago) do
      agenda_item.update!(meeting_section: second_section)
      meeting.touch_and_save_journals
    end
  end

  before do
    # The test schema already contains what the migration adds and journaling above filled it,
    # so remove it to simulate the state the backfill runs against.
    ActiveRecord::Base.connection.drop_table(:meeting_section_journals)
    ActiveRecord::Base.connection.remove_column(:meeting_agenda_item_journals, :meeting_section_id)
    Journal::MeetingAgendaItemJournal.update_all(presenter_id: nil)
  end

  def journals = meeting.journals.order(:version).to_a

  def agenda_item_journal_of(journal) = journal.agenda_item_journals.find_by(agenda_item_id: agenda_item.id)

  it "records in each journal the sections that existed by then" do
    migrate

    expect(journals.map { it.section_journals.pluck(:section_id) })
      .to match([
                  contain_exactly(meeting.own_backlog.id),
                  contain_exactly(meeting.own_backlog.id, first_section.id),
                  contain_exactly(meeting.own_backlog.id, first_section.id, second_section.id)
                ])
  end

  it "copies the current values of the sections" do
    migrate

    expect(journals.last.section_journals.find_by(section_id: second_section.id))
      .to have_attributes(title: "Decisions", position: second_section.position, backlog: false)
  end

  it "references the agenda item's current section only in journals recording that section" do
    migrate

    expect(agenda_item_journal_of(journals.second).meeting_section_id).to be_nil
    expect(agenda_item_journal_of(journals.third).meeting_section_id).to eq(second_section.id)
  end

  it "sets the agenda item's presenter in every journal" do
    migrate

    expect(journals.drop(1).map { agenda_item_journal_of(it).presenter_id }).to all(eq(presenter.id))
  end

  it "leaves the latest journal matching the current state, so the next save creates no journal" do
    migrate

    expect { meeting.touch_and_save_journals }.not_to change(Journal, :count)
  end
end
