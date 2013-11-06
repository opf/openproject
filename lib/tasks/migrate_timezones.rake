#-- encoding: UTF-8
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

namespace :migrations do
  desc "Use FROM environment variable to define a timezone to migrate from.
  Examples: LOCAL (PostGres), SYSTEM (MySQL), 'Europe/Berlin'"
  task :change_timestamps_to_utc => :environment do |task|
    def postgres?
      @postgres ||= ActiveRecord::Base.connection.instance_values["config"][:adapter] == "postgresql"
    end

    def mysql?
      @mysql ||= ActiveRecord::Base.connection.instance_values["config"][:adapter] == "mysql2"
    end

    raise "Error: Adapting Timestamps from system timezone to UTC is only supported for " +
      "postgres and mysql yet." unless postgres? || mysql?


    def readOldTimezone
      if postgres?
        @old_timezone = ActiveRecord::Base.connection.select_all(
                    "SELECT current_setting('timezone') AS timezone").first['timezone']
      elsif
        @old_timezone = ActiveRecord::Base.connection.select_all(
          "SELECT @@global.time_zone").first['@@global.time_zone']
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

        from_timezone = ENV['FROM'] || 'SYSTEM'

        ActiveRecord::Base.connection.execute "SET time_zone = #{from_timezone}"
      end
    end

    def setOldTimezone
      if postgres?
        ActiveRecord::Base.connection.execute "SET TIME ZONE #{@old_timezone}"
      elsif mysql?
        ActiveRecord::Base.connection.execute "SET time_zone = #{@old_timezone}"
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
        ActiveRecord::Base.connection.select_all <<-SQL
          select concat('UPDATE ',table_name, ' SET ', column_name, ' = CONVERT_TZ(', column_name, ', \\'#{@old_timezone}\\', \\'UTC\\');')
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
