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
require Rails.root.join("modules/meeting/db/migrate/20261010080000_add_unique_index_to_meeting_agenda_item_journals.rb")

RSpec.describe AddUniqueIndexToMeetingAgendaItemJournals, type: :model do
  subject(:migrate) { ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:up) } }

  shared_let(:meeting) { create(:meeting) }
  shared_let(:agenda_item) { create(:meeting_agenda_item, meeting:) }

  let(:journal) { meeting.journals.last }
  let(:duplicate) do
    journal.agenda_item_journals.find_by(agenda_item_id: agenda_item.id).dup.tap do |row|
      row.title = "Newer"
      row.save!(validate: false)
    end
  end

  before_all do
    meeting.save_journals
  end

  before do
    ActiveRecord::Migration.suppress_messages { described_class.new.migrate(:down) }
    duplicate
  end

  it "keeps only the newest row per journal and agenda item" do
    migrate

    expect(journal.agenda_item_journals.where(agenda_item_id: agenda_item.id).pluck(:id, :title))
      .to contain_exactly([duplicate.id, "Newer"])
  end

  it "adds the unique index" do
    migrate

    expect(ActiveRecord::Base.connection.indexes(:meeting_agenda_item_journals).map(&:name))
      .to include("idx_meeting_agenda_item_journals_journal_item")
  end
end
