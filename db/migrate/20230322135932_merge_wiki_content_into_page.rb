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

require_relative "migration_utils/utils"

class MergeWikiContentIntoPage < ActiveRecord::Migration[7.0]
  include ::Migration::Utils

  def change
    add_contents_columns_to_pages

    reversible do |dir|
      dir.up do
        change_null_values_on_contents
        update_wiki_pages_from_contents
        update_journals_to_pages
      end
      dir.down do
        insert_wiki_contents
        update_journals_to_contents
      end
    end

    change_null_values_on_pages

    drop_wiki_contents

    rename_and_adapt_journal_data
  end

  private

  def add_contents_columns_to_pages
    change_table :wiki_pages, bulk: true do |t|
      # null: false is set later on after the data is migrated
      t.references :author, index: true, null: true, foreign_key: { to_table: :users }
      t.text :text, limit: 16.megabytes
      # null: false is set later on after the data is migrated
      t.integer :lock_version, null: true
    end

    add_index :wiki_pages, :updated_at
  end

  def drop_wiki_contents
    drop_table :wiki_contents do |t|
      t.integer :page_id, null: false
      t.integer :author_id
      t.text :text, limit: 16.megabytes
      t.datetime :updated_at, null: false
      t.integer :lock_version, null: false

      t.index :author_id, name: "index_wiki_contents_on_author_id"
      t.index :page_id, name: "wiki_contents_page_id"
      t.index %i[page_id updated_at]
    end
  end

  def change_null_values_on_contents
    execute_sql(
      "
        UPDATE wiki_contents SET author_id = :deleted_user_id
        WHERE author_id NOT IN (SELECT id from users)
      ",
      deleted_user_id:
    )
  end

  def change_null_values_on_pages
    change_column_null :wiki_pages, :lock_version, false

    execute_sql("UPDATE wiki_pages SET author_id = :deleted_user_id WHERE author_id IS NULL", deleted_user_id:)

    change_column_null :wiki_pages, :author_id, false
  end

  def deleted_user_id
    # We use the model to make sure one is created in case it doesn't exist yet
    @deleted_user_id ||= DeletedUser.first.id
  end

  def rename_and_adapt_journal_data
    rename_table :wiki_content_journals, :wiki_page_journals
    remove_column :wiki_page_journals, :page_id, :bigint
  end

  def update_journals_to_pages
    execute <<~SQL.squish
      UPDATE
        journals
      SET
        journable_id = wiki_contents.page_id,
        journable_type = 'WikiPage',
        data_type = 'Journal::WikiPageJournal'
      FROM
        wiki_contents
      WHERE
        journals.journable_id = wiki_contents.id
      AND
        journals.journable_type = 'WikiContent'
      AND
        journals.data_type = 'Journal::WikiContentJournal'
    SQL
  end

  def update_journals_to_contents
    execute <<~SQL.squish
      UPDATE
        journals
      SET
        journable_id = wiki_contents.id,
        journable_type = 'WikiContent',
        data_type = 'Journal::WikiContentJournal'
      FROM
        wiki_contents
      WHERE
        journals.journable_id = wiki_contents.page_id
      AND
        journals.journable_type = 'WikiPage'
      AND
        journals.data_type = 'Journal::WikiPageJournal'
    SQL
  end

  def update_wiki_pages_from_contents
    execute <<~SQL.squish
      UPDATE
        wiki_pages
      SET
        text = wiki_contents.text,
        author_id = wiki_contents.author_id,
        lock_version = wiki_contents.lock_version
      FROM
        wiki_contents
      WHERE
        wiki_contents.page_id = wiki_pages.id
    SQL
  end

  def insert_wiki_contents
    execute <<~SQL.squish
      INSERT INTO
        wiki_contents (
          page_id,
          author_id,
          text,
          updated_at,
          lock_version
        )
      SELECT
        id,
        author_id,
        text,
        updated_at,
        lock_version
      FROM
        wiki_pages
    SQL
  end
end
