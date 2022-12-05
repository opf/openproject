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
