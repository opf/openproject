class CostsIssueObserver < ActiveRecord::Observer
  observe :issue

  def after_update(issue)
    if issue.project_id_changed?
      CostEntry.update_all({:project_id => issue.project_id}, {:issue_id => id})
    end 
  end
  
  def before_update(issue)
    # FIXME: remove this method once controller_issues_move_before_save is in 0.9-stable
    if issue.project_id_changed? && issue.cost_object_id && !issue.project.cost_object_ids.include?(issue.cost_object_id)
      issue.cost_object = nil
    end
  end
end
    