class AddNameToICalTokens < ActiveRecord::Migration[7.0]
  def up
    # Add column with default value to avoid null values for existing records in preview environment
    add_column :ical_token_query_assignments, :name, :string, null: false, default: "Not provided in earlier version"
    # Remove default value after migration and applying it to existing records
    change_column_default :ical_token_query_assignments, :name, nil
  end

  def down
    remove_column :ical_token_query_assignments, :name
    # Remove all ical tokens as they have been created with a name before and
    # are not intended to be used without a name
    Token::ICal.delete_all
  end
end
