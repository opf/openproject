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

require Rails.root.join("db/migrate/migration_utils/migration_squasher").to_s
# This migration aggregates the migrations detailed in MIGRATION_FILES
class ToV710AggregatedDocumentsMigrations < ActiveRecord::Migration[5.1]
  MIGRATION_FILES = <<-MIGRATIONS
    20130807085604_create_document_journals.rb
    20130814131242_create_documents_tables.rb
    20140320140001_legacy_document_journal_data.rb
  MIGRATIONS

  def up
    Migration::MigrationSquasher.squash(migrations) do
      create_table "documents", id: :integer do |t|
        t.integer  "project_id", default: 0, null: false
        t.integer  "category_id", default: 0, null: false
        t.string   "title", limit: 60, default: "", null: false
        t.text     "description"
        t.datetime "created_on"
      end
      add_index "documents", ["category_id"], name: "index_documents_on_category_id"
      add_index "documents", ["created_on"], name: "index_documents_on_created_on"
      add_index "documents", ["project_id"], name: "documents_project_id"

      create_table :document_journals, id: :integer do |t|
        t.integer  :journal_id, null: false
        t.integer  :project_id, default: 0, null: false
        t.integer  :category_id, default: 0, null: false
        t.string   :title, limit: 60, default: "", null: false
        t.text     :description
        t.datetime :created_on
      end
    end
  end

  def down
    drop_table :documents
    drop_table :document_journals
  end

  private

  def migrations
    MIGRATION_FILES.split.map do |m|
      m.gsub(/_.*\z/, "")
    end
  end
end
