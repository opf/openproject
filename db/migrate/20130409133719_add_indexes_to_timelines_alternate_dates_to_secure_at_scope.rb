class AddIndexesToTimelinesAlternateDatesToSecureAtScope < ActiveRecord::Migration
  def self.up
    add_index :timelines_alternate_dates,
              [:updated_at, :planning_element_id, :scenario_id],
              :unique => true,
              :name => 'index_ad_on_updated_at_and_planning_element_id'
  end

  def self.down
    change_table(:timelines_alternate_dates) do |t|
      t.remove_index :name => 'index_ad_on_updated_at_and_planning_element_id'
    end
  end
end
