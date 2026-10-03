# frozen_string_literal: true

# -- copyright
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
# ++

require Rails.root.join("db/migrate/tables/base").to_s

class Tables::TimeEntries < Tables::Base
  def self.table(migration) # rubocop:disable Metrics/AbcSize
    create_table migration do |t|
      t.bigint :project_id, null: false
      t.bigint :user_id, null: false
      t.belongs_to :work_package, index: false
      t.float :hours, null: true
      t.text :comments
      t.bigint :activity_id, null: true
      t.date :spent_on, null: false
      t.integer :tyear, null: false
      t.integer :tmonth, null: false
      t.integer :tweek, null: false
      t.timestamps precision: nil, default: -> { "CURRENT_TIMESTAMP" }
      t.decimal :overridden_costs, precision: 15, scale: 4
      t.decimal :costs,            precision: 15, scale: 4
      t.bigint :rate_id
      t.references :logged_by, foreign_key: { to_table: :users }, index: true, null: false
      t.boolean :ongoing, null: false, default: false, index: true
      t.integer :start_time, null: true
      t.string :time_zone, null: true
      # The polymorphic reference's index duplicates the one on
      # entity_type and entity_id below.
      t.references :entity, polymorphic: true

      t.index %i[entity_type entity_id]
      t.index :activity_id, name: "index_time_entries_on_activity_id"
      t.index :created_at, name: "index_time_entries_on_created_at"
      t.index :work_package_id, name: "time_entries_issue_id" # issue_id for backwards compatibility
      t.index :project_id, name: "time_entries_project_id"
      t.index :user_id, name: "index_time_entries_on_user_id"
      t.index %i[project_id updated_at]
      t.index %i[user_id ongoing], unique: true, where: "ongoing = true"
    end
  end
end
