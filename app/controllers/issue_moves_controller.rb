class IssueMovesController < ApplicationController
  default_search_scope :issues
  before_filter :find_issues, :check_project_uniqueness
  before_filter :authorize
  
  def new
    prepare_for_issue_move
    render :layout => false if request.xhr?
  end

  def create
    prepare_for_issue_move

    if request.post?
      new_tracker = params[:new_tracker_id].blank? ? nil : @target_project.trackers.find_by_id(params[:new_tracker_id])
      unsaved_issue_ids = []
      moved_issues = []
      @issues.each do |issue|
        issue.reload
        issue.init_journal(User.current)
        call_hook(:controller_issues_move_before_save, { :params => params, :issue => issue, :target_project => @target_project, :copy => !!@copy })
        if r = issue.move_to_project(@target_project, new_tracker, {:copy => @copy, :attributes => extract_changed_attributes_for_move(params)})
          moved_issues << r
        else
          unsaved_issue_ids << issue.id
        end
      end
      set_flash_from_bulk_issue_save(@issues, unsaved_issue_ids)

      if params[:follow]
        if @issues.size == 1 && moved_issues.size == 1
          redirect_to :controller => 'issues', :action => 'show', :id => moved_issues.first
        else
          redirect_to :controller => 'issues', :action => 'index', :project_id => (@target_project || @project)
        end
      else
        redirect_to :controller => 'issues', :action => 'index', :project_id => @project
      end
      return
    end
  end

  private

  def prepare_for_issue_move
    @issues.sort!
    @copy = params[:copy_options] && params[:copy_options][:copy]
    @allowed_projects = Issue.allowed_target_projects_on_move
    @target_project = @allowed_projects.detect {|p| p.id.to_s == params[:new_project_id]} if params[:new_project_id]
    @target_project ||= @project    
    @trackers = @target_project.trackers
    @available_statuses = Workflow.available_statuses(@project)
  end

  def extract_changed_attributes_for_move(params)
    changed_attributes = {}
    [:assigned_to_id, :status_id, :start_date, :due_date, :priority_id].each do |valid_attribute|
      unless params[valid_attribute].blank?
        changed_attributes[valid_attribute] = (params[valid_attribute] == 'none' ? nil : params[valid_attribute])
      end
    end
    changed_attributes
  end

end
