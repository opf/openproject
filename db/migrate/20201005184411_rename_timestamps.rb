class RenameTimestamps < ActiveRecord::Migration[6.0]
  def change
    alter_name_and_defaults(:comments, :created_on, :created_at)
    alter_name_and_defaults(:comments, :updated_on, :updated_at)

    alter_name_and_defaults(:messages, :created_on, :created_at)
    alter_name_and_defaults(:messages, :updated_on, :updated_at)

    alter_name_and_defaults(:versions, :created_on, :created_at)
    alter_name_and_defaults(:versions, :updated_on, :updated_at)

    alter_name_and_defaults(:users, :created_on, :created_at)
    alter_name_and_defaults(:users, :updated_on, :updated_at)

    alter_name_and_defaults(:wiki_pages, :created_on, :created_at)
    alter_name_and_defaults(:wiki_redirects, :created_on, :created_at)

    alter_name_and_defaults(:tokens, :created_on, :created_at)

    alter_name_and_defaults(:settings, :updated_on, :updated_at)

    alter_name_and_defaults(:cost_queries, :created_on, :created_at)
    alter_name_and_defaults(:cost_queries, :updated_on, :updated_at)

    alter_name_and_defaults(:wiki_contents, :updated_on, :updated_at)

    add_timestamp_column(:journals, :updated_at, :created_at)

    add_timestamp_column(:roles, :created_at, 'CURRENT_TIMESTAMP')
    add_timestamp_column(:roles, :updated_at, 'CURRENT_TIMESTAMP')
  end

  private

  def alter_name_and_defaults(table, old_column_name, new_column_name)
    rename_column table, old_column_name, new_column_name

    change_column_default table, new_column_name, from: nil, to: -> { 'CURRENT_TIMESTAMP' }
  end

  def add_timestamp_column(table, column_name, from_column = nil)
    add_column table, column_name, :timestamp, default: -> { 'CURRENT_TIMESTAMP' }

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE
            #{table}
          SET #{column_name} = #{from_column}
        SQL
      end
    end

    change_column_null table, column_name, true
  end
end
