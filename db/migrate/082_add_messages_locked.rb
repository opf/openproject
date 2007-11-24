class AddMessagesLocked < ActiveRecord::Migration
  def self.up
    add_column :messages, :locked, :boolean, :default => false
  end

  def self.down
    remove_column :messages, :locked
  end
end
