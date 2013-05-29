class RemoveContentFromTimelinesTimelines < ActiveRecord::Migration
  def self.up
    change_table(:timelines) do |t|
      t.remove :content
    end
  end

  def self.down
    change_table(:timelines) do |t|
      t.text :content
    end
  end
end
