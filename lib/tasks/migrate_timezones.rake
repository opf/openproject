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
  desc "Use FROM environment variable to define a timezone to migrate from.
  Examples: LOCAL (PostgreSQL), SYSTEM (MySQL), 'Europe/Berlin' (PostgreSQL), Europe/Berlin (MySQL)
  (Note the quotes in the different examples)"
  task change_timestamps_to_utc: :environment do |_task|
    def postgres?
      @postgres ||= ActiveRecord::Base.connection.instance_values['config'][:adapter] == 'postgresql'
    end

    def mysql?
      @mysql ||= ActiveRecord::Base.connection.instance_values['config'][:adapter] == 'mysql2'
    end

    raise 'Error: Adapting Timestamps from system timezone to UTC is only supported for ' +
      'postgres and mysql yet.' unless postgres? || mysql?

    def readOldTimezone
      if postgres?
        @old_timezone = ActiveRecord::Base.connection.select_all(
          "SELECT current_setting('timezone') AS timezone").first['timezone']
      end
    end

    def setFromTimezone
      if postgres?
        from_timezone = ENV['FROM'] || 'LOCAL'
        ActiveRecord::Base.connection.execute "SET TIME ZONE #{from_timezone}"
      elsif mysql?
        converted_time = ActiveRecord::Base.connection.select_all( \
          "SELECT CONVERT_TZ('2013-11-06 15:13:42', 'SYSTEM', 'UTC')").first.values.first

        if converted_time.nil?
          raise <<-error
            Error: timezone information has not been loaded into mysql, please execute
            mysql_tzinfo_to_sql <path-to-zoneinfo> | mysql -u root mysql
            Hint: a likely location of <path-to-zoneinfo> is /usr/share/zoneinfo
            see: http://dev.mysql.com/doc/refman/5.0/en/mysql-tzinfo-to-sql.html
          error
        end
      end
    end

    def setOldTimezone
      if postgres?
        ActiveRecord::Base.connection.execute "SET TIME ZONE #{@old_timezone}"
      end
    end

    def getQueries
      if postgres?
        ActiveRecord::Base.connection.select_all <<-SQL
          select 'UPDATE ' || table_name || ' SET ' || column_name || ' = ' || column_name || '::timestamptz at time zone ''utc'';'
          from information_schema.columns
          where table_schema='public'
          and data_type like 'timestamp without time zone'
        SQL
      elsif mysql?
        from_timezone = ENV['FROM'] || 'SYSTEM'

        ActiveRecord::Base.connection.select_all <<-SQL
          select concat('UPDATE ',table_name, ' SET ', column_name, ' = CONVERT_TZ(', column_name, ', \\'#{from_timezone}\\', \\'UTC\\');')
          from information_schema.columns
          where table_schema = '#{ActiveRecord::Base.connection.current_database}' and data_type like 'datetime'
        SQL
      end
    end

    readOldTimezone

    begin
      setFromTimezone

      getQueries.each do |statement|
        ActiveRecord::Base.connection.execute statement.values.first
      end

    ensure
      setOldTimezone
    end
  end
end
