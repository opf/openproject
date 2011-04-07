class AddStartDateToVersions < ActiveRecord::Migration
  def self.up
    add_column :versions, :start_date, :date
  end

  def self.down
    remove_column :versions, :start_date
  end
end
