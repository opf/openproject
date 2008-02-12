class ChangeProjectsDescriptionToText < ActiveRecord::Migration
  def self.up
    change_column :projects, :description, :text, :null => true
  end

  def self.down
  end
end
