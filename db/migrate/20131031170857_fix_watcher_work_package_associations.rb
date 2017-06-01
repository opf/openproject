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

class FixWatcherWorkPackageAssociations < ActiveRecord::Migration[4.2]
  def up
    rename_watchable_type('Issue', 'WorkPackage')
    adapt_planning_element_ids
    rename_watchable_type('Timelines::PlanningElement', 'WorkPackage')
  end

  def down
    revert_planning_element_ids_and_types
    rename_watchable_type('WorkPackage', 'Issue')
  end

  private

  def rename_watchable_type(source_type, target_type)
    ActiveRecord::Base.connection.execute "UPDATE #{watchers_table}
                                           SET watchable_type=#{quote_value(target_type)}
                                           WHERE watchable_type=#{quote_value(source_type)}"
  end

  def adapt_planning_element_ids
    if postgres?
      ActiveRecord::Base.connection.execute <<-SQL
        UPDATE #{watchers_table}
         SET watchable_id = tmp.new_id
         FROM (
          SELECT first.watchable_id, second.new_id
          FROM #{watchers_table} AS first
          LEFT JOIN #{legacy_planning_elements_table} AS second
          ON first.watchable_id = second.id
          WHERE first.watchable_type = #{quote_value('Timelines::PlanningElement')}
          ) AS tmp
          WHERE watchers.watchable_id = tmp.watchable_id
          AND watchers.watchable_type = #{quote_value('Timelines::PlanningElement')};
      SQL
    elsif mysql?
      ActiveRecord::Base.connection.execute <<-SQL
        UPDATE #{watchers_table} AS first
        LEFT JOIN #{legacy_planning_elements_table} AS second ON first.watchable_id = second.id
        SET watchable_id = second.new_id
        WHERE watchable_type = #{quote_value('Timelines::PlanningElement')};
      SQL
    end
  end

  def revert_planning_element_ids_and_types
    if postgres?
      ActiveRecord::Base.connection.execute <<-SQL
        UPDATE #{watchers_table}
         SET watchable_id = tmp.id,
             watchable_type = #{quote_value('Timelines::PlanningElement')}
         FROM (
          SELECT first.watchable_id, second.id
          FROM #{watchers_table} AS first
          INNER JOIN #{legacy_planning_elements_table} AS second
          ON first.watchable_id = second.new_id
          WHERE first.watchable_type = #{quote_value('WorkPackage')}
          ) AS tmp
          WHERE watchers.watchable_id = tmp.watchable_id
          AND watchers.watchable_type = #{quote_value('WorkPackage')};
      SQL
    elsif mysql?
      ActiveRecord::Base.connection.execute <<-SQL
        UPDATE #{watchers_table} AS first
        INNER JOIN #{legacy_planning_elements_table} AS second ON first.watchable_id = second.new_id
        SET watchable_id = second.id,
            watchable_type = #{quote_value('Timelines::PlanningElement')}
        WHERE watchable_type = #{quote_value('WorkPackage')};
      SQL
    end
  end

  def watchers_table
    ActiveRecord::Base.connection.quote_table_name 'watchers'
  end

  def legacy_planning_elements_table
    ActiveRecord::Base.connection.quote_table_name 'legacy_planning_elements'
  end

  def quote_value(value)
    ActiveRecord::Base.connection.quote value
  end

  def postgres?
    ActiveRecord::Base.connection.instance_values['config'][:adapter] == 'postgresql'
  end

  def mysql?
    ActiveRecord::Base.connection.instance_values['config'][:adapter] == 'mysql2'
  end
end
