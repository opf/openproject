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
  namespace :strong_passwords do
    def migrations_to_reregister
      @migrations_to_reregister ||= ['20130628092725']
    end

    desc "Prepares database schema changed by the plug-in 'Strong Passwords' for follow-up migrations"
    task reregister: :environment do |_task|
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
      ActiveRecord::Base.connection.quote_table_name 'schema_migrations'
    end

    def quote_value(name)
      ActiveRecord::Base.connection.quote name
    end
  end
end
