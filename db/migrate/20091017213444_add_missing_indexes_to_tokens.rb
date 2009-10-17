class AddMissingIndexesToTokens < ActiveRecord::Migration
  def self.up
    add_index :tokens, :user_id
  end

  def self.down
    remove_index :tokens, :user_id
  end
end
