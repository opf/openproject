class OrderTasksUsingTree < ActiveRecord::Migration
  def self.up
    last_task = {}
    ActiveRecord::Base.transaction do
      Task.find(:all, :conditions => "not parent_id is NULL", :order => "project_id ASC, parent_id ASC, position ASC").each do |t|
        begin
          t.move_after last_task[t.parent_id] if last_task[t.parent_id]
        rescue
          # nested tasks break this migrations. Task order not that
          # big a deal, proceed
        end

        last_task[t.parent_id] = t.id
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
