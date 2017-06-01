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

require_relative 'migration_utils/utils'

class FixParentIdsInWorkPackageJournalsOfFormerPlanningElements < ActiveRecord::Migration[4.2]
  include Migration::Utils

  def up
    if postgres?
      ActiveRecord::Base.connection.execute <<-SQL
        UPDATE work_package_journals AS o_wpj
          SET parent_id = tmp.lpea_new_id
          FROM (
            SELECT j.id, lpe.new_id, lpe.parent_id, wpj.id AS wpj_id, wpj.parent_id AS wpj_parent_id, lpea.id, lpea.new_id AS lpea_new_id FROM legacy_planning_elements AS lpe
            JOIN journals AS j ON j.journable_id = lpe.new_id AND j.journable_type = 'WorkPackage'
            JOIN work_package_journals AS wpj ON wpj.journal_id = j.id
            LEFT JOIN legacy_planning_elements AS lpea ON lpea.id = wpj.parent_id
            WHERE wpj.parent_id IS NOT NULL AND lpea.new_id IS NOT NULL
            ORDER BY j.journable_id, j.id
          ) AS tmp
        WHERE o_wpj.id = tmp.wpj_id;
      SQL
    elsif mysql?
      ActiveRecord::Base.connection.execute <<-SQL
        UPDATE work_package_journals AS wpj
          JOIN journals AS j ON (j.id = wpj.journal_id)
          JOIN legacy_planning_elements AS lpe ON (lpe.new_id = j.journable_id)
          LEFT JOIN legacy_planning_elements AS parent ON parent.id = wpj.parent_id
        SET wpj.parent_id = parent.new_id
        WHERE parent.id IS NOT NULL;
      SQL
    end
  end

  def down
    # nop
  end
end
