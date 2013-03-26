class RemoveGanttRelatedDataFromDatabase < ActiveRecord::Migration
  def up
    EnabledModule.where(:name => 'gantt').delete_all
  end

  def down
    raise IrreversibleMigration
  end
end
