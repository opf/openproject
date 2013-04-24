require_dependency 'issue'

class CostsIssueObserver < ActiveRecord::Observer
  unloadable
  observe :issue

  def after_update(issue)
    if issue.project_id_changed?
      # TODO: This only works with the global cost_rates
      CostEntry.update_all({:project_id => issue.project_id}, {:issue_id => issue.id})
    end
    
  end
  
  def before_update(issue)
    # FIXME: remove this method once controller_issues_move_before_save is in 0.9-stable
    if issue.project_id_changed? && issue.cost_object_id && !issue.project.cost_object_ids.include?(issue.cost_object_id)
     issue.cost_object = nil
    end
    # true
  end
end

ActiveRecord::Base.observers.push :costs_issue_observer
