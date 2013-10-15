class IndexOnUsers < ActiveRecord::Migration
  def change
    add_index :users, [:type, :login]
    add_index :users, [:type, :status]
  end
end
