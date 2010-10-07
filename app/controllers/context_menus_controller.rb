class ContextMenusController < ApplicationController
  helper :watchers
  
  def issues
    @issues = Issue.find_all_by_id(params[:ids], :include => :project)
    if (@issues.size == 1)
      @issue = @issues.first
      @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    else
      @allowed_statuses = @issues.map do |i|
        i.new_statuses_allowed_to(User.current)
      end.inject do |memo,s|
        memo & s
      end
    end
    @projects = @issues.collect(&:project).compact.uniq
    @project = @projects.first if @projects.size == 1

    @can = {:edit => (@project && User.current.allowed_to?(:edit_issues, @project)),
            :log_time => (@project && User.current.allowed_to?(:log_time, @project)),
            :update => (@project && (User.current.allowed_to?(:edit_issues, @project) || (User.current.allowed_to?(:change_status, @project) && @allowed_statuses && !@allowed_statuses.empty?))),
            :move => (@project && User.current.allowed_to?(:move_issues, @project)),
            :copy => (@issue && @project.trackers.include?(@issue.tracker) && User.current.allowed_to?(:add_issues, @project)),
            :delete => User.current.allowed_to?(:delete_issues, @projects)
            }
    if @project
      @assignables = @project.assignable_users
      @assignables << @issue.assigned_to if @issue && @issue.assigned_to && !@assignables.include?(@issue.assigned_to)
      @trackers = @project.trackers
    end
    
    @priorities = IssuePriority.all.reverse
    @statuses = IssueStatus.find(:all, :order => 'position')
    @back = back_url
    
    render :layout => false
  end
  
end
