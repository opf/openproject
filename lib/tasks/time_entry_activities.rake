#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'pg'

namespace 'openproject' do
  desc 'Fixes an error in the migration to 10.4 by fetching data from a backup.'
  task :reassign_time_entry_activities do
    unless ENV['BACKUP_DATABASE_URL']
      puts <<~MSG


        The 'BACKUP_DATABASE_URL' environment variable must be defined.
        That variable needs to contain the connection string to the database from which the activities are to be fetched.


      MSG
      next
    end

    check_statement = <<~SQL
      SELECT
        te_source.id,
        enumerations.parent_id
      FROM
        time_entries te_source
      INNER JOIN
        enumerations
        ON te_source.activity_id = enumerations.id AND enumerations.parent_id IS NOT NULL AND enumerations.type = 'TimeEntryActivity'
    SQL

    select_statement = <<~SQL
      SELECT
        te_source.id,
        COALESCE(enumerations.parent_id, enumerations.id) activity_id
      FROM time_entries te_source
      LEFT OUTER JOIN
        enumerations
        ON te_source.activity_id = enumerations.id
      WHERE enumerations.type = 'TimeEntryActivity'
    SQL

    entries = begin
                connection = ActiveRecord::Base
                             .establish_connection(ENV['BACKUP_DATABASE_URL'])
                             .connection

                if connection.select_all(check_statement).any?
                  connection.select_all(select_statement)
                end
              rescue PG::ConnectionBad, ActiveRecord::NoDatabaseError, LoadError => e
                puts <<~MSG

                  The 'BACKUP_DATABASE_URL' environment variable is incorrect. The script cannot connect to the backup database:
                  #{e.message}

                MSG
                next
              ensure
                connection&.close
              end

    if entries.nil? || entries.empty?
      puts <<~MSG


        As there are no project specific activities in the backup, nothing needs to be done.


      MSG
      next
    end

    entries_string = entries.map { |entry| "(#{entry['id']}, #{entry['activity_id']})" }.join(', ')

    update_statement = <<~SQL
      UPDATE time_entries
      SET activity_id = val.activity_id
      FROM (values
        #{entries_string}
      ) as val (id, activity_id)
      WHERE time_entries.id = val.id
    SQL

    puts <<~MSG

      Fixing #{entries.length} time entries.
    MSG

    connection = ActiveRecord::Base
                  .establish_connection(Rails.configuration.database_configuration[Rails.env])
                  .connection
    connection.execute(update_statement)

    connection.close

    puts <<~MSG
      Done.

    MSG
  end
end
