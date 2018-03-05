#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require Rails.root.join('db', 'migrate', 'migration_utils', 'utils').to_s

class LegacyIssuesCostsDataToWorkPackages < ActiveRecord::Migration[5.0]
  def up
    return unless migration_applicable?

    execute <<-SQL
      UPDATE work_packages
      SET cost_object_id = (SELECT legacy_issues.cost_object_id
                            FROM legacy_issues
                            WHERE legacy_issues.id = work_packages.id
                            LIMIT 1)
    SQL
  end

  def down
    return unless migration_applicable?

    execute <<-SQL
      UPDATE legacy_issues
      SET cost_object_id = (SELECT work_packages.cost_object_id
                            FROM work_packages
                            WHERE work_packages.id = legacy_issues.id
                            LIMIT 1)
    SQL
  end

  private

  def migration_applicable?
    ActiveRecord::Base.connection.table_exists?('legacy_issues') &&
      ActiveRecord::Base.connection.columns('legacy_issues').map(&:name).include?('cost_object_id')
  end
end
