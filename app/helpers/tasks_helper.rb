module TasksHelper
  unloadable

  def task_color_or_default(task)
    task.nil? || task.assigned_to.nil? ? '#EFEFEF' : task.assigned_to.backlogs_preference(:task_color)
  end
end