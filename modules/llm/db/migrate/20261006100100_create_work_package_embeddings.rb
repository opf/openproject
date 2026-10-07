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

class CreateWorkPackageEmbeddings < ActiveRecord::Migration[8.1]
  def change
    create_table :work_package_embeddings do |t|
      t.references :work_package, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      # model_id is the provider's external model name (e.g. "text-embedding-3-large").
      # Stored alongside the vector so that stale rows from a previous model can be
      # excluded from search without touching the feature binding.
      t.string :model_id, null: false
      t.integer :dimensions, null: false
      t.timestamps null: false
    end

    # Vector column added separately: Rails does not register the pgvector
    # "vector" type, so a block-style column definition would silently emit the
    # wrong SQL. A raw ALTER TABLE uses the type verbatim.
    reversible do |dir|
      dir.up   { execute "ALTER TABLE work_package_embeddings ADD COLUMN embedding vector NOT NULL" }
      dir.down {} # dropped with the table
    end
  end
end
