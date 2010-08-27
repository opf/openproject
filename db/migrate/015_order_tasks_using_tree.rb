class OrderTasksUsingTree < ActiveRecord::Migration
  def self.up
    last_task = {}
    ActiveRecord::Base.transaction do
      Task.find(:all, :conditions => "id <> root_id", :order => "project_id ASC, fixed_version_id ASC, position ASC").each do |t|
        t.move_after last_task[t.parent_id] if last_task[t.parent_id]

        last_task[t.parent_id] = t.id
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
