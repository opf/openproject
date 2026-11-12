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

class CreateDocumentTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :document_types do |t|
      t.string :name
      t.integer :position
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end

    add_index :document_types, :name, unique: true
    add_reference :documents, :type, foreign_key: { to_table: :document_types }

    reversible do |dir|
      dir.up do
        migrate_existing_categories_to_types
        migrate_existing_documents_categories_references_to_types

        change_column_null :documents, :category_id, true
        change_column_null :document_journals, :category_id, true
      end

      # No-op for down migration
    end
  end

  private

  def migrate_existing_categories_to_types
    say_with_time "migrating document categories to types" do
      execute <<~SQL.squish
        WITH existing_document_categories AS (
          SELECT
            name,
            ROW_NUMBER() OVER (
              ORDER BY position ASC
            ) AS position,
            COALESCE(is_default, false) AS is_default
          FROM enumerations
          WHERE type = 'DocumentCategory'
        )
        INSERT INTO document_types (name, position, is_default, created_at, updated_at)
          SELECT name, position, is_default, NOW(), NOW()
          FROM existing_document_categories
          ON CONFLICT (name) DO NOTHING
      SQL
    end
  end

  def migrate_existing_documents_categories_references_to_types
    say_with_time "migrating existing documents categories references to types" do
      execute <<~SQL.squish
        UPDATE documents
        SET type_id = document_types.id
        FROM enumerations
        JOIN document_types ON document_types.name = enumerations.name
        WHERE documents.category_id = enumerations.id
        AND enumerations.type = 'DocumentCategory'
      SQL
    end
  end
end
