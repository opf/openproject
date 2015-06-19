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

class JournalActivitiesData < ActiveRecord::Migration
  include Migration::Utils

  def up
    say_with_time_silently "Changing activity type from 'issues' to 'work_packages'" do
      update <<-SQL
      UPDATE #{journals_table}
      SET activity_type = #{work_package_activity}
      WHERE journable_type = #{work_package_type}
      SQL
    end
  end

  def down
    if legacy_planning_elements_table_exists?

      say_with_time_silently "Changing activity type from 'work_packages' to 'planning_elements'" do
        update <<-SQL
        UPDATE #{journals_table}
        SET activity_type = #{planning_element_activity}
        WHERE #{journals_table}.journable_id IN (SELECT new_id
                                                 FROM #{legacy_planning_elements_table})
        SQL
      end
    else
      say 'Can not distinguish between former planning_elements and issues. Assuming all to be former issues.'
    end

    say_with_time_silently "Changing activity type from 'work_packages' to 'issues'" do
      update <<-SQL
      UPDATE #{journals_table}
      SET activity_type = #{issue_activity}
      WHERE activity_type = #{work_package_activity}
      SQL
    end
  end

  private

  def legacy_planning_elements_table_exists?
    suppress_messages do
      table_exists? legacy_planning_elements_table
    end
  end

  def journals_table
    ActiveRecord::Base.connection.quote_table_name('journals')
  end

  def legacy_planning_elements_table
    ActiveRecord::Base.connection.quote_table_name('legacy_planning_elements')
  end

  def work_package_type
    ActiveRecord::Base.connection.quote('WorkPackage')
  end

  def work_package_activity
    ActiveRecord::Base.connection.quote('work_packages')
  end

  def planning_element_activity
    ActiveRecord::Base.connection.quote('timelines_planning_elements')
  end

  def issue_activity
    ActiveRecord::Base.connection.quote('issues')
  end
end
