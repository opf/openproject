class AddGinTrgmIndexOnJournalsAndCustomValues < ActiveRecord::Migration[7.0]
  def up
    safe_enable_pg_trgm_extension

    if extensions.include?('pg_trgm')
      add_index(:journals, :notes, using: 'gin', opclass: :gin_trgm_ops)
      add_index(:custom_values, :value, using: 'gin', opclass: :gin_trgm_ops)
    end
  end

  def down
    remove_index(:journals, :notes, if_exists: true)
    remove_index(:custom_values, :value, if_exists: true)
    drop_pg_trgm_extension
  end

  private

  def safe_enable_pg_trgm_extension
    ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA pg_catalog;")
  rescue StandardError => e
    raise unless e.message =~ /pg_trgm/

    # Rollback the transaction in order to recover from the error.
    ActiveRecord::Base.connection.execute 'ROLLBACK'

    warn <<~MESSAGE


      \e[33mWARNING:\e[0m Could not find the `pg_trgm` extension for PostgreSQL.
      In order to benefit from this performance improvement, please install the postgresql-contrib module
      for your PostgreSQL installation and re-run this migration.

      Read more about the contrib module at `https://www.postgresql.org/docs/current/contrib.html` .
      To re-run this migration use the following command `bin/rails db:migrate:redo VERSION=20230328154645`

    MESSAGE
  end

  def drop_pg_trgm_extension
    ActiveRecord::Base.connection.execute("DROP EXTENSION IF EXISTS pg_trgm CASCADE;")
  end
end
