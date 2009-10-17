class AddMissingIndexesToMembers < ActiveRecord::Migration
  def self.up
    add_index :members, :user_id
    add_index :members, :project_id
  end

  def self.down
    remove_index :members, :user_id
    remove_index :members, :project_id
  end
end
