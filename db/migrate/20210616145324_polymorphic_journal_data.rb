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

class PolymorphicJournalData < ActiveRecord::Migration[6.1]
  # The wiki content table got renamed after writing the migration initially.
  class WikiContentJournal < ApplicationRecord
    self.table_name = "wiki_content_journals"
  end

  def up
    # For performance reasons, the existing indices are first removed and then readded after the
    # update is done.
    add_data_and_remove_index

    data_journals.each do |journal_data|
      execute <<~SQL.squish
        UPDATE journals
        SET data_id = data.id, data_type = '#{journal_data.name}'
        FROM #{journal_data.table_name} data
        WHERE data.journal_id = journals.id
      SQL

      remove_column journal_data.table_name, :journal_id
    end

    add_indices
  end

  def down
    data_journals.each do |journal_data|
      add_column journal_data.table_name, :journal_id, :integer
      add_index journal_data.table_name, :journal_id

      execute <<~SQL.squish
        UPDATE #{journal_data.table_name} data
        SET journal_id = journals.id
        FROM journals
        WHERE data.id = journals.data_id AND journals.data_type = '#{journal_data.name}'
      SQL
    end

    remove_reference :journals, :data, polymorphic: true
  end

  def data_journals
    [::Journal::ChangesetJournal,
     ::Journal::AttachmentJournal,
     ::Journal::MessageJournal,
     ::Journal::NewsJournal,
     WikiContentJournal,
     ::Journal::WorkPackageJournal,
     ::Journal::BudgetJournal,
     ::Journal::TimeEntryJournal,
     ::Journal::DocumentJournal,
     ::Journal::MeetingJournal,
     ::Journal::MeetingContentJournal]
  end

  def add_data_and_remove_index
    change_table :journals do |j|
      j.references :data, polymorphic: true, index: false

      j.remove_index :journable_id
      j.remove_index :journable_type
      j.remove_index :created_at
      j.remove_index :user_id
      j.remove_index :activity_type
      j.remove_index %i[journable_type journable_id version]
    end
  end

  def add_indices
    change_table :journals do |j|
      j.index :journable_id
      j.index :journable_type
      j.index :created_at
      j.index :user_id
      j.index :activity_type
      j.index %i[journable_type journable_id version], unique: true
      j.index %i[data_id data_type], unique: true
    end
  end
end
