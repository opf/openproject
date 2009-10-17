class AddMissingIndexesToNews < ActiveRecord::Migration
  def self.up
    add_index :news, :author_id
  end

  def self.down
    remove_index :news, :author_id
  end
end
