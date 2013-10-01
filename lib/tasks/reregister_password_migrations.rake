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
  namespace :strong_passwords do
    def migrations_to_reregister
      @migrations_to_reregister ||= ['20130628092725']
    end

    desc "Prepares database schema changed by the plug-in 'Strong Passwords' for follow-up migrations"
    task :reregister => :environment do |task|
      if strong_passwords_changed_schema
        puts "Adapt 'Strong Passwords' schema changes..."
        rename_strong_password_columns
        reregister_migrations
      else
        puts "No 'Strong Passwords' schema changes detected. Nothing else to do..."
      end
    end

    def strong_passwords_changed_schema
      User.column_names.include? 'failed_login_on'
    end

    def rename_strong_password_columns
      ActiveRecord::Migration.rename_column :users, :failed_login_on, :last_failed_login_on
    end

    def reregister_migrations
      migrations_to_reregister.each do |migration_name|
        puts migration_name

        ActiveRecord::Base.connection.execute <<-SQL
          INSERT INTO #{schema_name}
          VALUES (#{quote_value(migration_name)})
        SQL
      end
    end

    def schema_name
      ActiveRecord::Base.connection.quote_table_name "schema_migrations"
    end

    def quote_value name
      ActiveRecord::Base.connection.quote name
    end
  end
end
