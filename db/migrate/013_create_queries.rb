class CreateQueries < ActiveRecord::Migration
  def self.up
    create_table :queries, :force => true do |t|
      t.column "project_id", :integer
      t.column "name", :string, :default => "", :null => false
      t.column "filters", :text
      t.column "user_id", :integer, :default => 0, :null => false
      t.column "is_public", :boolean, :default => false, :null => false
    end
  end

  def self.down
    drop_table :queries
  end
end
