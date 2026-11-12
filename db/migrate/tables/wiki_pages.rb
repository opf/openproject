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

require_relative "base"

class Tables::WikiPages < Tables::Base
  def self.table(migration) # rubocop:disable Metrics/AbcSize
    create_table migration do |t|
      t.bigint :wiki_id, null: false
      t.string :title, null: false
      t.datetime :created_at, precision: nil, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.boolean :protected, default: false, null: false
      t.bigint :parent_id
      t.string :slug, null: false
      t.datetime :updated_at, precision: nil, null: false, index: true
      t.references :author, index: true, null: false, foreign_key: { to_table: :users }
      t.text :text, limit: 16.megabytes
      t.integer :lock_version, null: false

      t.index %i[wiki_id slug], name: "wiki_pages_wiki_id_slug", unique: true
      t.index :parent_id, name: "index_wiki_pages_on_parent_id"
      t.index %i[wiki_id title], name: "wiki_pages_wiki_id_title"
      t.index :wiki_id, name: "index_wiki_pages_on_wiki_id"
    end
  end
end
