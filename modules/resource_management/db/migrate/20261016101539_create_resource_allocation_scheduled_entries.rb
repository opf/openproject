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

class CreateResourceAllocationScheduledEntries < ActiveRecord::Migration[8.1]
  def up
    create_table :resource_allocation_scheduled_entries do |t|
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :resource_allocation, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.date :allocated_on, null: false
      t.integer :minutes, null: false
      t.integer :overtime_minutes, null: false, default: 0

      t.index %i[resource_allocation_id allocated_on], unique: true
      t.index %i[user_id allocated_on]
      t.index %i[user_id allocated_on],
              where: "overtime_minutes > 0",
              name: "index_resource_allocation_scheduled_entries_on_overtime"
    end

    ResourceAllocations::RebuildSchedulesJob.perform_later
  end

  def down
    drop_table :resource_allocation_scheduled_entries
  end
end
