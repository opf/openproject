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

class CreateGrid < ActiveRecord::Migration[5.1]
  def change
    create_grids
    create_grid_widgets
  end

  private

  def create_grids
    create_table :grids do |t|
      t.integer :row_count, null: false
      t.integer :column_count, null: false
      t.string :type

      t.references :user

      t.timestamps
    end
  end

  def create_grid_widgets
    create_table :grid_widgets do |t|
      t.integer :start_row, null: false
      t.integer :end_row, null: false
      t.integer :start_column, null: false
      t.integer :end_column, null: false
      t.string :identifier
      t.text :options
      t.references :grid
    end
  end
end
