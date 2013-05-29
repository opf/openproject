class CreateTimelinesAlternateDates < ActiveRecord::Migration
  def self.up
    create_table(:alternate_dates) do |t|
      t.column :start_date, :date, :null => false
      t.column :end_date,   :date, :null => false

      t.belongs_to :scenario
      t.belongs_to :planning_element

      t.timestamps

    end
    add_index :alternate_dates, :planning_element_id
    add_index :alternate_dates, :scenario_id
  end

  def self.down
    drop_table(:alternate_dates)
  end
end
