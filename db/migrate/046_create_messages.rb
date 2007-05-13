class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.column :board_id, :integer, :null => false
      t.column :parent_id, :integer
      t.column :subject, :string, :default => "", :null => false
      t.column :content, :text
      t.column :author_id, :integer
      t.column :replies_count, :integer, :default => 0, :null => false
      t.column :last_reply_id, :integer
      t.column :created_on, :datetime, :null => false
      t.column :updated_on, :datetime, :null => false
    end
    add_index :messages, [:board_id], :name => :messages_board_id
    add_index :messages, [:parent_id], :name => :messages_parent_id
  end

  def self.down
    drop_table :messages
  end
end
