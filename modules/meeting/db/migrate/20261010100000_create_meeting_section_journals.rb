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

class CreateMeetingSectionJournals < ActiveRecord::Migration[8.1]
  def change
    create_table :meeting_section_journals do |t|
      t.integer :journal_id, null: false
      t.bigint :section_id, null: false
      t.string :title
      t.integer :position
      t.boolean :backlog, default: false, null: false
    end

    add_index :meeting_section_journals,
              %i[journal_id section_id],
              unique: true,
              name: :idx_meeting_section_journals_journal_section

    add_column :meeting_agenda_item_journals, :meeting_section_id, :bigint
  end
end
