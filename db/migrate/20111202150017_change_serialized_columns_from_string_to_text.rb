class ChangeSerializedColumnsFromStringToText < ActiveRecord::Migration
  def self.up
    change_table :my_projects_overviews do |t|
      t.change_default "left", nil
      t.change_default "right", nil
      t.change_default "top", nil
      t.change_default "hidden", nil

      t.change "left", :text, :null => false
      t.change "right", :text, :null => false
      t.change "top", :text, :null => false
      t.change "hidden", :text, :null => false
    end
  end

  def self.down
    change_table :my_projects_overviews do |t|
      t.change "left", :string, :default => ["wiki", "projectdetails", "issuetracking"].to_yaml, :null => false
      t.change "right", :string, :default => ["members", "news"].to_yaml, :null => false
      t.change "top", :string, :default => [].to_yaml, :null => false
      t.change "hidden", :string, :default => [].to_yaml, :null => false
    end
  end
end
