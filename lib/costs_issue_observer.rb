class CostsIssueObserver < ActiveRecord::Observer
  observe :issue

  def after_update(issue)
    if issue.project_id_changed?
      CostEntry.update_all({:project_id => issue.project_id}, {:issue_id => id})
    end 
  end
end
    