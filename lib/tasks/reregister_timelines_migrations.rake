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

namespace :migrations do
  namespace :timelines do
    def name_map
      # note that 20120215093215_add_indexes_to_timelines_models.rb of the timelines plugins was
      # removed without replacement and that the contents of it was put into a multitude of migrations
      @name_map ||= { '20110929081301-chiliproject_timelines' => '20130409133700',
                      '20110929083343-chiliproject_timelines' => '20130409133701',
                      '20110929144754-chiliproject_timelines' => '20130409133702',
                      '20110930125321-chiliproject_timelines' => '20130409133703',
                      '20111005114335-chiliproject_timelines' => '20130409133704',
                      '20111005133556-chiliproject_timelines' => '20130409133705',
                      '20111006070115-chiliproject_timelines' => '20130409133706',
                      '20111108075045-chiliproject_timelines' => '20130409133707',
                      '20111108134440-chiliproject_timelines' => '20130409133708',
                      '20111108145338-chiliproject_timelines' => '20130409133709',
                      '20111122083825-chiliproject_timelines' => '20130409133710',
                      '20120106155245-chiliproject_timelines' => '20130409133711',
                      '20120109111640-chiliproject_timelines' => '20130409133712',
                      '20120109140237-chiliproject_timelines' => '20130409133713',
                      '20120109153625-chiliproject_timelines' => '20130409133714',
                      '20120206165120-chiliproject_timelines' => '20130409133715',
                      '20120215093215-chiliproject_timelines' => nil,
                      '20120221143844-chiliproject_timelines' => '20130409133717',
                      '20120221144552-chiliproject_timelines' => '20130409133718',
                      '20120306161515-chiliproject_timelines' => '20130409133719',
                      '20120322111436-chiliproject_timelines' => '20130409133720',
                      '20120518151232-chiliproject_timelines' => '20130409133721',
                      '20120522094843-chiliproject_timelines' => '20130409133722',
                      '20120524130128-chiliproject_timelines' => '20130409133723' }
    end

    def new_name_of(old_name)
      name_map[old_name]
    end

    def old_migration_names
      name_map.keys
    end

    def migrations_to_remove
      ['20120215093215-chiliproject_timelines']
    end

    def quote_value(name)
      ActiveRecord::Base.connection.quote name
    end

    def schema_name
      ActiveRecord::Base.connection.quote_table_name 'schema_migrations'
    end

    def remove_migrations
      migrations_to_remove.each do |migration_name|
        puts migration_name

        ActiveRecord::Base.connection.execute <<-SQL
          DELETE FROM #{schema_name}
          WHERE version=#{quote_value(migration_name)}
        SQL
      end
    end

    def rename_migrations
      old_migration_names.each do |migration_name|
        puts migration_name
        new_name = new_name_of(migration_name)

        ActiveRecord::Base.connection.execute <<-SQL
          UPDATE #{schema_name}
          SET version=#{quote_value(new_name)}
          WHERE version=#{quote_value(migration_name)}
        SQL
      end
    end

    desc 'rewrites existing timelines migrations to the newly named migrations'
    task reregister: :environment do |_task|
      remove_migrations
      rename_migrations
    end
  end
end
