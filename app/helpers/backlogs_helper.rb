module BacklogsHelper

  def backlog_date(backlog, field_name)
    d = backlog.send(field_name)
    d.nil? ? "(not set)" : d.strftime("%Y-%m-%d")
  end
  
  def mark_closed_if_so(item_or_task)
    return if item_or_task.nil?
    item_or_task.issue.status.is_closed? ? "closed" : ""
  end
    
  def link_to_main_backlog
    link_to "All Backlog Items", :controller => 'items', :project_id => @project.id
  end
  
  def link_to_backlog(backlog)
    link_to backlog.version.name, backlog_url(backlog)
  end
  
  def say_version(issue)
    issue.fixed_version.nil? ? "-" : issue.fixed_version.name
  end

end
