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

    def setFromTimezone
      if postgres?
        from_timezone = ENV['FROM'] || 'LOCAL'
        @old_timezone = ActiveRecord::Base.connection.select_all(
                    "SELECT current_setting('timezone') AS timezone").first['timezone']
        ActiveRecord::Base.connection.execute "SET TIME ZONE #{from_timezone}"
      elsif mysql?
        from_timezone = ENV['FROM'] || 'SYSTEM'
        @old_timezone = ActiveRecord::Base.connection.select_all(
          "SELECT @@global.time_zone").first['@@global.time_zone']
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
