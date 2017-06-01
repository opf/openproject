#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

require 'yaml'

require_relative 'migration_utils/utils'

class MigrateUserRights < ActiveRecord::Migration[4.2]
  include Migration::Utils

  COLUMN = 'permissions'

  PERMISSIONS = {
    view_issues: :view_work_packages,
    add_issues: :add_work_packages,
    edit_issues: :edit_work_packages,
    move_issues: :move_work_packages,
    delete_issues: :delete_work_packages,

    export_issues: :export_work_packages,
    manage_issue_relations: :manage_work_package_relations,

    add_issue_notes: :add_work_package_notes,
    edit_issue_notes: :edit_work_package_notes,

    view_issue_watchers: :view_work_package_watchers,
    add_issue_watchers: :add_work_package_watchers,
    delete_issue_watchers: :delete_work_package_watchers,

    view_planning_elements: :view_work_packages,
    edit_planning_elements: :edit_work_packages,
    delete_planning_elements: :delete_work_packages,

    edit_own_issue_notes: :edit_own_work_package_notes,
    move_planning_elements_to_trash: nil
  }

  def up
    say_with_time_silently 'Update role permissions' do
      update_column_values('roles', [COLUMN], update_role_permissions(PERMISSIONS), filter)
    end
  end

  def down
    # select only nonambiguous permissions
    permissions = PERMISSIONS.select { |_k, v| PERMISSIONS.values.count(v) == 1 }

    say_with_time_silently 'Restore role permissions' do
      update_column_values('roles', [COLUMN], update_role_permissions(permissions.invert), filter)
    end

    ambiguous_permissions = PERMISSIONS.select { |_k, v| PERMISSIONS.values.count(v) > 1 }
                            .keys

    say <<-WARNING
      This down migration can't restore the following permission: #{ambiguous_permissions.inspect}
    WARNING
  end

  private

  def filter
    "#{COLUMN} LIKE '%issue%' OR #{COLUMN} LIKE '%planning_element%'"
  end

  def update_role_permissions(permissions)
    Proc.new do |row|
      unless row[COLUMN].nil?
        role_permissions = YAML.load row[COLUMN]

        role_permissions.map! do |p| permissions.has_key?(p) ? permissions[p] : p end

        row[COLUMN] = YAML.dump role_permissions.flatten
      end

      UpdateResult.new(row, true)
    end
  end
end
