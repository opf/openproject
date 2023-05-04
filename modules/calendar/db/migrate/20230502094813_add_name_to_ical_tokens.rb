class AddNameToIcalTokens < ActiveRecord::Migration[7.0]
  def change
    # Add column with default value to avoid null values for existing records in preview environment
    add_column :ical_token_query_assignments, :name, :string, null: false, default: 'Not provided in earlier version'
    # Remove default value after migration and applying it to existing records
    change_column_default :ical_token_query_assignments, :name, nil
  end
end
