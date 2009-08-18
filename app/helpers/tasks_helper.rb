module TasksHelper
  def mark_closed_if_so(item_or_task)
    return if item_or_task.nil?
    item_or_task.issue.status.is_closed? ? "closed" : ""
  end
end