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

class CreateRecurringWorkPackages < ActiveRecord::Migration[8.1]
  def change
    create_series_table
    create_occurrences_table
  end

  private

  def create_series_table
    create_table :recurring_work_packages_series do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.integer :frequency, null: false, default: 0
      t.integer :interval, null: false, default: 1
      t.date :start_date, null: false
      t.integer :end_after, null: false, default: 0
      t.date :end_date
      t.integer :iterations

      t.timestamps
    end
  end

  def create_occurrences_table
    create_table :recurring_work_packages_occurrences do |t|
      t.references :series,
                   null: false,
                   index: false,
                   foreign_key: { to_table: :recurring_work_packages_series, on_delete: :cascade }
      t.references :work_package, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false
      t.date :scheduled_date, null: false

      t.timestamps
    end

    add_index :recurring_work_packages_occurrences, %i[series_id position], unique: true
  end
end
