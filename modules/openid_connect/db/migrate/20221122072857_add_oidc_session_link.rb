class AddOidcSessionLink < ActiveRecord::Migration[7.0]
  def change
    create_unlogged_tables = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.create_unlogged_tables

    begin
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.create_unlogged_tables = true
      create_table :oidc_user_session_links do |t|
        t.string :oidc_session, null: false, index: true
        t.references :session, index: true, foreign_key: { to_table: 'sessions', on_delete: :cascade }

        t.timestamps
      end
    ensure
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.create_unlogged_tables = create_unlogged_tables
    end
  end
end
