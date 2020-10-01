class RenameTimestampOnTimeEntry < ActiveRecord::Migration[6.0]
  def change
    rename_column :time_entries, :created_on, :created_at
    rename_column :time_entries, :updated_on, :updated_at

    change_column_default :time_entries, :created_at, from: nil, to: -> { 'CURRENT_TIMESTAMP' }
    change_column_default :time_entries, :updated_at, from: nil, to: -> { 'CURRENT_TIMESTAMP' }
  end
end
