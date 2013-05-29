class CreateTimelinesColors < ActiveRecord::Migration
  def self.up
    create_table(:colors) do |t|
      t.column :name,    :string, :null => false
      t.column :hexcode, :string, :null => false, :length => 7

      t.column :position, :integer, :default => 1, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table(:colors)
  end
end
