class AddTimelinesResponsibleIdToProjects < ActiveRecord::Migration
  def self.up
    change_table(:projects) do |t|
      t.belongs_to :responsible

      t.index :responsible_id
    end
  end

  def self.down
    change_table(:projects) do |t|
      t.remove_belongs_to :responsible
    end
  end
end
