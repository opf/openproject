class RemoveOrphanedTokens < ActiveRecord::Migration[7.0]
  def up
    Token::Base.where.not(user_id: User.select(:id)).delete_all
    add_foreign_key :tokens, :users
  end

  def down
    # Nothing to do
  end
end
