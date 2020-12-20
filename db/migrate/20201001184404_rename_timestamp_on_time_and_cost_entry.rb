class RenameTimestampOnTimeAndCostEntry < ActiveRecord::Migration[6.0]
  def change
    alter_name_and_defaults(:time_entries)
    alter_name_and_defaults(:cost_entries)
  end

  private

  def alter_name_and_defaults(table)
    rename_column table, :created_on, :created_at
    rename_column table, :updated_on, :updated_at

    change_column_default table, :created_at, from: nil, to: -> { 'CURRENT_TIMESTAMP' }
    change_column_default table, :updated_at, from: nil, to: -> { 'CURRENT_TIMESTAMP' }
  end
end
