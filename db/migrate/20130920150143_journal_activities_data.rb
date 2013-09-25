#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
      say "Can not distinguish between former planning_elements and issues. Assuming all to be former issues."
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
