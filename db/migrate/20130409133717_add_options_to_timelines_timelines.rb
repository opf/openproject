class AddOptionsToTimelinesTimelines < ActiveRecord::Migration
  def self.up
    change_table(:timelines_timelines) do |t|
      t.text :options
    end
  end

  def self.down
    change_table(:timelines_timelines) do |t|
      t.remove :options
    end
  end
end
