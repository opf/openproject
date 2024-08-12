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

class RenamePlanningElemntTypeColorsToColors < ActiveRecord::Migration[5.1]
  def up
    # Fix existing indexes due to old migration away from timeline_colors
    # This hasn't happened automatically in Rails < 4 with the 2013 migration of timelines_colors
    if index_name_exists?(:planning_element_type_colors, :timelines_colors_pkey)
      rename_index :planning_element_type_colors, :timelines_colors_pkey, :planning_element_type_colors_pkey
    end

    rename_table :planning_element_type_colors, :colors
    remove_column :colors, :position
  end

  def down
    rename_table :colors, :planning_element_type_colors

    change_table :planning_element_type_colors do
      t.integer :position, default: 1, null: true
    end
  end
end
