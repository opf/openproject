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
  Examples: LOCAL
            'Europe/Berlin'"
  task :change_timestamps_to_utc => :environment do |task|
    def postgres?
      ActiveRecord::Base.connection.instance_values["config"][:adapter] == "postgresql"
    end

    raise "Error: Adapting Timestamps from system timezone to UTC is only supported for " +
          "postgres yet." unless postgres?

    old_timezone = ActiveRecord::Base.connection.select_all(
                    "SELECT current_setting('timezone') AS timezone").first['timezone']

    from_timezone = ENV['FROM'] || 'LOCAL'

    begin
      ActiveRecord::Base.connection.execute "SET TIME ZONE #{from_timezone}"

      queries = ActiveRecord::Base.connection.select_all <<-SQL
        select 'UPDATE ' || table_name || ' SET ' || column_name || ' = ' || column_name || '::timestamptz at time zone ''utc'';'
        from information_schema.columns
        where table_schema='public'
        and data_type like 'timestamp without time zone'
      SQL

      mem = queries.inject([]) do |mem, entry|
        mem << entry.values.first
      end

      ActiveRecord::Base.connection.execute mem.join("\n")

    ensure
      ActiveRecord::Base.connection.execute "SET TIME ZONE '#{old_timezone}'"
    end
  end

end
