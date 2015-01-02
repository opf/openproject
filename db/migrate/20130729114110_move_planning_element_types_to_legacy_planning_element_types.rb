#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class MovePlanningElementTypesToLegacyPlanningElementTypes < ActiveRecord::Migration
  def up
    rename_table :default_planning_element_types, :legacy_default_planning_element_types
    rename_table :enabled_planning_element_types, :legacy_enabled_planning_element_types
    rename_table :planning_element_types,         :legacy_planning_element_types

    remove_column :work_packages, :planning_element_type_id
  end

  def down
    rename_table :legacy_default_planning_element_types, :default_planning_element_types
    rename_table :legacy_enabled_planning_element_types, :enabled_planning_element_types
    rename_table :legacy_planning_element_types,         :planning_element_types

    add_column :work_packages, :planning_element_type_id, :integer
  end
end
