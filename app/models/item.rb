class Item < ActiveRecord::Base
  unloadable
  belongs_to   :issue
  belongs_to   :backlog
  acts_as_list :scope => 'backlog_id=#{backlog_id} AND parent_id=#{parent_id}'
  acts_as_tree :order => "position ASC, created_at ASC"

  def append_comment(user, comment)
    journal = issue.init_journal(User.current, @notes)
  end

  def self.create(params, project)
    issue = create_issue(params, project)
    item  = find_by_issue_id(issue.id)
    item.update_attributes! params[:item]
    item.update_position params
    item
  end
  
  def subject
    issue.nil? ? "" : issue.subject
  end
  
  def self.update(params)
    item = find(params[:id])
    
    # Fix bug #42 to remove this condition
    if params[:item][:backlog_id].to_i != 0
      params[:issue][:fixed_version_id] = Backlog.find(params[:item][:backlog_id]).version.id
    else
      params[:issue][:fixed_version_id] = ""
      params[:item].delete(:backlog_id)
    end
    
    item.issue.update_attributes! params[:issue]
    item.remove_from_list    
    item.update_attributes! params[:item]
    item.update_position params
    item
  end

  # CLEANMEUP: Dirty dirty dirty 
  def self.create_issue(params, project)
    issue = Issue.new
    # issue.copy_from(params[:copy_from]) if params[:copy_from]
    issue.project = project
    # Tracker must be set before custom field values
    issue.tracker ||= project.trackers.find(:first)
    # @issue.tracker ||= @project.trackers.find((params[:issue] && params[:issue][:tracker_id]) || params[:tracker_id] || :first)
    # if @issue.tracker.nil?
    #   render_error 'No tracker is associated to this project. Please check the Project settings.'
    #   return
    # end
    if params[:issue].is_a?(Hash)
      issue.attributes = params[:issue]
      issue.watcher_user_ids = params[:issue]['watcher_user_ids'] if User.current.allowed_to?(:add_issue_watchers, project)
    end
    issue.author = User.current
    
    default_status = IssueStatus.default
    # unless default_status
    #   render_error 'No default issue status is defined. Please check your configuration (Go to "Administration -> Issue statuses").'
    #   return
    # end    
    # issue.status = default_status
    # allowed_statuses = ([default_status] + default_status.find_new_statuses_allowed_to(User.current.roles_for_project(@project), @issue.tracker)).uniq
    
    requested_status = IssueStatus.find_by_id(params[:issue][:status_id])
    # Check that the user is allowed to apply the requested status
    # @issue.status = (@allowed_statuses.include? requested_status) ? requested_status : default_status
    if issue.save
      # attach_files(issue, params[:attachments])
      # flash[:notice] = l(:notice_successful_create)
      # call_hook(:controller_issues_new_after_save, { :params => params, :issue => issue})
      # redirect_to(params[:continue] ? { :action => 'new', :tracker_id => @issue.tracker } :
      #                                 { :action => 'show', :id => @issue })
      # return
    end		
    
    issue.reload
    issue
  end

  def self.delete_item(issue)
    find_by_issue_id(issue.id).destroy
  end

  def self.find_by_project(project)
    find(:all, :include => :issue, :conditions => "issues.project_id=#{project.id} and parent_id=0", :order => "position ASC")
  end

  def self.update_from_issue(issue)
    backlog         = Backlog.find_by_version_id(issue.fixed_version_id)
    item            = find_by_issue_id(issue.id) || Item.new()
    item.issue_id   = issue.id
    item.backlog_id = (backlog.nil? ? 0 : backlog.id)
    item.save 
  end  
  
  def update_position(params)
    if params[:prev]=="" || params[:prev].nil?
      insert_at 1
    else
      prev = Item.find(params[:prev]).position
      insert_at prev + 1
    end
  end
  
end
