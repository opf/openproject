class ChangeProjectsDescriptionToText < ActiveRecord::Migration
  def self.up
    change_column :projects, :description, :text, :default => ''
  end

  def self.down
  end
end
