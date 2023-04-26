class AddGinTrgmIndexOnJournalsAndCustomValues < ActiveRecord::Migration[7.0]
  def change
    safe_enable_pg_trgm_extension

    if extensions.include?('pg_trgm')
      add_index(:journals, :notes, using: 'gin', opclass: :gin_trgm_ops)
      add_index(:custom_values, :value, using: 'gin', opclass: :gin_trgm_ops)
    end
  end

  private

  def safe_enable_pg_trgm_extension
    enable_extension("pg_trgm")
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
end
