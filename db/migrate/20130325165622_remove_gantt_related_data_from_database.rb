class RemoveGanttRelatedDataFromDatabase < ActiveRecord::Migration
  def up
    EnabledModule.where(:name => 'gantt').delete_all
  end
end
