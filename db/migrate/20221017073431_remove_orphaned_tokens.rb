class RemoveOrphanedTokens < ActiveRecord::Migration[7.0]
  def up
    Token::Base.where.not(user_id: User.select(:id)).delete_all

    # Make sure we have bigint columns on both sides so the foreign key can be added.
    # It could be that they are of type numeric if the data was migrated from MySQL once.
    make_bigint! :users, :id
    make_bigint! :tokens, :user_id

    add_foreign_key :tokens, :users
  end

  def down
    # Nothing to do
  end

  def make_bigint!(table, field)
    return if bigint? table, field

    change_column table, field, :bigint
  end

  def bigint?(table, field)
    get_column_type(table, field).to_s == "bigint"
  end

  def get_column_type(table, field)
    ActiveRecord::Base.connection.columns(table.to_s).find { |col| col.name == field.to_s }&.sql_type
  end
end
