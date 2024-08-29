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

require Rails.root.to_s + "/db/migrate/migration_utils/module_renamer"
require Rails.root.to_s + "/db/migrate/migration_utils/setting_renamer"

class RenameTimeAndCostModule < ActiveRecord::Migration[6.0]
  def up
    module_renamer.add_to_enabled("costs", %w[time_tracking costs_module reporting_module])
    module_renamer.remove_from_enabled(%w[time_tracking costs_module reporting_module])
    module_renamer.add_to_default("costs", %w[time_tracking costs_module reporting_module])
    setting_renamer.rename("plugin_costs", "plugin_costs")
  end

  def down
    # We do not know if all three where actually enabled but having them enabled will keep the functionality
    module_renamer.add_to_enabled("time_tracking", "costs")
    module_renamer.add_to_enabled("costs_module", "costs")
    module_renamer.add_to_enabled("reporting_module", "costs")

    module_renamer.remove_from_enabled("costs")
    module_renamer.add_to_default(%w[costs_module time_tracking reporting_module], "costs")
    setting_renamer.rename("plugin_costs", "plugin_costs")
  end

  def module_renamer
    Migration::MigrationUtils::ModuleRenamer
  end

  def setting_renamer
    Migration::MigrationUtils::SettingRenamer
  end
end
