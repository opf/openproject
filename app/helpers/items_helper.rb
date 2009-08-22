module ItemsHelper
  unloadable
  
  def assigned_to_id_or_empty(item)
    item.new_record? ? "" : item.issue.assigned_to_id
  end
  
  def assignee_name_or_empty(item)
    issue = item.issue
    issue.nil? || issue.assigned_to.nil? ? "" : "#{issue.assigned_to.firstname} #{issue.assigned_to.lastname}"
  end
  
  def description_or_empty(item)
    item.new_record? ? "" : textilizable(item.issue, :description)
  end
  
  def element_id_or_empty(item)
    item.new_record? ? "" : "item_#{item.id}"
  end
  
  def issue_id_or_default(item)
    item.new_record? ? "#<span class='issue_id'>0</span>" : 
                       link_to("#<span class='issue_id'>#{item.issue.id}</span>", :controller => "issues", :action => "show", :id => item.issue.id)
  end
  
  def mark_if_closed(item)
    !item.new_record? && item.issue.status.is_closed? ? "closed" : ""
  end
  
  def mark_if_task(item)
    item.parent_id == 0 ? "" : "task"
  end
  
  
  def points_or_empty(item)
    item.points.nil? ? 0 : item.points
  end
  
  def record_id_or_empty(item)
    item.new_record? ? "" : item.id
  end
  
  def status_id_or_default(item)
    item.new_record? ? IssueStatus.find(:first, :order => "position ASC").id : item.issue.status.id
  end
  
  def status_label_or_default(item)
    item.new_record? ? IssueStatus.find(:first, :order => "position ASC").name : item.issue.status.name
  end

  def textile_description_or_empty(item)
    item.new_record? ? "" : item.issue.description
  end

  def tracker_id_or_empty(item)
    item.new_record? ? "" : item.issue.tracker_id
  end

  def tracker_name_or_empty(item)
    item.new_record? ? "" : item.issue.tracker.name
  end
end
