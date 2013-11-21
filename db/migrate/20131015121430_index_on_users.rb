class IndexOnUsers < ActiveRecord::Migration
  def change
    add_index :users, [:type, :login], :length => {:type => 255, :login => 255}
    add_index :users, [:type, :status]
  end
end
