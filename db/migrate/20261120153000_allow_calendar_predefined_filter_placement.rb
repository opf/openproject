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

class AllowCalendarPredefinedFilterPlacement < ActiveRecord::Migration[8.1]
  CONSTRAINT_NAME = "valid_predefined_work_package_filter_placement"
  PREVIOUS_PLACEMENTS = "placement IN ('project_overview', 'work_packages', 'gantt')"
  CALENDAR_PLACEMENTS = "placement IN ('project_overview', 'work_packages', 'gantt', 'calendar')"

  def up
    replace_constraint(CALENDAR_PLACEMENTS)
  end

  def down
    execute "UPDATE predefined_work_package_filters SET placement = NULL WHERE placement = 'calendar'"
    replace_constraint(PREVIOUS_PLACEMENTS)
  end

  private

  def replace_constraint(expression)
    remove_check_constraint :predefined_work_package_filters, name: CONSTRAINT_NAME
    add_check_constraint :predefined_work_package_filters, expression, name: CONSTRAINT_NAME
  end
end
