class AddTimelinesResponsibleIdToProjects < ActiveRecord::Migration
  def self.up
    change_table(:projects) do |t|
      t.belongs_to :timelines_responsible

      t.index :timelines_responsible_id
    end
  end

  def self.down
    change_table(:projects) do |t|
      t.remove_belongs_to :timelines_responsible
    end
  end
end
