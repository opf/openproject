class CreateRepositories < ActiveRecord::Migration
  def self.up
    create_table :repositories, :force => true do |t|
      t.column "project_id", :integer, :default => 0, :null => false
      t.column "url", :string, :default => "", :null => false
    end
  end

  def self.down
    drop_table :repositories
  end
end
