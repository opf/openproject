require_relative "./migration_utils/column"

class RemoveOrphanedTokens < ActiveRecord::Migration[7.0]
  def up
    Token::Base.where.not(user_id: User.select(:id)).delete_all

    # Make sure we have bigint columns on both sides so the foreign key can be added.
    # It could be that they are of type numeric if the data was migrated from MySQL once.
    change_column_type! :users, :id, :bigint
    change_column_type! :tokens, :user_id, :bigint

    add_foreign_key :tokens, :users

    User.reset_column_information
    Token::Base.reset_column_information
  end

  def down
    remove_foreign_key :tokens, :users
  end

  def change_column_type!(table, column, type)
    Migration::MigrationUtils::Column.new(connection, table, column).change_type! type
  end
end
