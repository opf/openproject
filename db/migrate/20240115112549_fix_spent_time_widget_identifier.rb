class FixSpentTimeWidgetIdentifier < ActiveRecord::Migration[7.0]
  def up
    execute("UPDATE grid_widgets SET identifier = 'time_entries_list' WHERE identifier = 'time_entries_project'")
  end

  def down
    execute("UPDATE grid_widgets SET identifier = 'time_entries_project' WHERE identifier = 'time_entries_list'")
  end
end
