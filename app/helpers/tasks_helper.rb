module TasksHelper
  unloadable

  def build_inline_style(task)
    task.nil? || task.assigned_to.nil? ? '' : "style='background-color:#{task.assigned_to.backlogs_preference(:task_color)}'"
  end
  
  def remaining_hours(item)
    item.remaining_hours.nil? || item.remaining_hours==0 ? "" : item.remaining_hours
  end
  
end