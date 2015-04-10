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

require_relative 'migration_utils/utils'

class MigrateSettingsToWorkPackage < ActiveRecord::Migration
  include Migration::Utils

  COLUMN = 'name'

  SETTINGS = {
    'issue_list_summable_columns' => 'work_package_list_summable_columns',
    'issue_list_default_columns' => 'work_package_list_default_columns',
    'issues_export_limit' => 'work_packages_export_limit',
    'issue_done_ratio' => 'work_package_done_ratio',
    'cross_project_issue_relations' => 'cross_project_work_package_relations',
    'display_subprojects_issues' => 'display_subprojects_work_packages',
    'issue_startdate_is_adddate' => 'work_package_startdate_is_adddate'
  }

  def up
    say_with_time_silently 'Update settings' do
      update_column_values('settings', [COLUMN], update_settings(SETTINGS), filter)
    end
  end

  def down
    say_with_time_silently 'Restore settings' do
      update_column_values('settings', [COLUMN], update_settings(SETTINGS.invert), filter)
    end
  end

  private

  def filter
    "#{COLUMN} LIKE '%issue%'"
  end

  def update_settings(settings)
    Proc.new do |row|
      merge_setting = !row[COLUMN].nil? && settings.has_key?(row[COLUMN])

      row[COLUMN] = settings[row[COLUMN]] if merge_setting

      UpdateResult.new(row, merge_setting)
    end
  end
end
