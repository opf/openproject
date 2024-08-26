#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class MigrateTimestampsToWithTimezone < ActiveRecord::Migration[7.0]
  def up
    migrate_to_timestampz
  end

  def down
    migrate_to_timestamp
  end

  private

  def migrate_to_timestampz
    execute <<~SQL.squish
      DO $$
      DECLARE
      t record;
      BEGIN
        FOR t IN
          SELECT column_name, table_name, data_type
          FROM information_schema.columns
          WHERE
            table_schema = ANY (SELECT unnest(string_to_array(replace(setting, '"$user"', CURRENT_USER), ', ')) FROM pg_settings WHERE name = 'search_path')
            AND data_type = 'timestamp without time zone'
        LOOP
          EXECUTE 'ALTER TABLE ' || t.table_name || ' ALTER COLUMN ' || t.column_name || ' TYPE timestamp with time zone USING ' || t.column_name || ' AT TIME ZONE ''UTC''';
        END LOOP;
      END$$;
    SQL
  end

  def migrate_to_timestamp
    execute <<~SQL.squish
      DO $$
      DECLARE
      t record;
      BEGIN
        FOR t IN
          SELECT column_name, table_name, data_type
          FROM information_schema.columns
          WHERE
            table_schema = ANY (SELECT unnest(string_to_array(replace(setting, '"$user"', CURRENT_USER), ', ')) FROM pg_settings WHERE name = 'search_path')
            AND data_type = 'timestamp with time zone'
        LOOP
          EXECUTE 'ALTER TABLE ' || t.table_name || ' ALTER COLUMN ' || t.column_name || ' TYPE timestamp without time zone USING ' || t.column_name || ' AT TIME ZONE ''UTC''';
        END LOOP;
      END$$;
    SQL
  end
end
