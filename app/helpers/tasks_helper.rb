module TasksHelper
  unloadable
  
  def issue_link_or_empty(task)
    task.new_record? ? "" : link_to(task.id, {:controller => "issues", :action => "show", :id => task}, {:target => "_blank"})
  end
  
end