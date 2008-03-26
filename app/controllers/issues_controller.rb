# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class IssuesController < ApplicationController
  layout 'base'
  menu_item :new_issue, :only => :new
  
  before_filter :find_issue, :only => [:show, :edit, :destroy_attachment]
  before_filter :find_issues, :only => [:bulk_edit, :move, :destroy]
  before_filter :find_project, :only => [:new, :update_form, :preview]
  before_filter :authorize, :except => [:index, :changes, :preview, :update_form, :context_menu]
  before_filter :find_optional_project, :only => [:index, :changes]
  accept_key_auth :index, :changes

  helper :journals
  helper :projects
  include ProjectsHelper   
  helper :custom_fields
  include CustomFieldsHelper
  helper :ifpdf
  include IfpdfHelper
  helper :issue_relations
  include IssueRelationsHelper
  helper :watchers
  include WatchersHelper
  helper :attachments
  include AttachmentsHelper
  helper :queries
  helper :sort
  include SortHelper
  include IssuesHelper

  def index
    sort_init "#{Issue.table_name}.id", "desc"
    sort_update
    retrieve_query
    if @query.valid?
      limit = per_page_option
      respond_to do |format|
        format.html { }
        format.atom { }
        format.csv  { limit = Setting.issues_export_limit.to_i }
        format.pdf  { limit = Setting.issues_export_limit.to_i }
      end
      @issue_count = Issue.count(:include => [:status, :project], :conditions => @query.statement)
      @issue_pages = Paginator.new self, @issue_count, limit, params['page']
      @issues = Issue.find :all, :order => sort_clause,
                           :include => [ :assigned_to, :status, :tracker, :project, :priority, :category, :fixed_version ],
                           :conditions => @query.statement,
                           :limit  =>  limit,
                           :offset =>  @issue_pages.current.offset
      respond_to do |format|
        format.html { render :template => 'issues/index.rhtml', :layout => !request.xhr? }
        format.atom { render_feed(@issues, :title => l(:label_issue_plural)) }
        format.csv  { send_data(issues_to_csv(@issues, @project).read, :type => 'text/csv; header=present', :filename => 'export.csv') }
        format.pdf  { send_data(render(:template => 'issues/index.rfpdf', :layout => false), :type => 'application/pdf', :filename => 'export.pdf') }
      end
    else
      # Send html if the query is not valid
      render(:template => 'issues/index.rhtml', :layout => !request.xhr?)
    end
  end
  
  def changes
    sort_init "#{Issue.table_name}.id", "desc"
    sort_update
    retrieve_query
    if @query.valid?
      @journals = Journal.find :all, :include => [ :details, :user, {:issue => [:project, :author, :tracker, :status]} ],
                                     :conditions => @query.statement,
                                     :limit => 25,
                                     :order => "#{Journal.table_name}.created_on DESC"
    end
    @title = (@project ? @project.name : Setting.app_title) + ": " + (@query.new_record? ? l(:label_changes_details) : @query.name)
    render :layout => false, :content_type => 'application/atom+xml'
  end
  
  def show
    @custom_values = @project.custom_fields_for_issues(@issue.tracker).collect { |x| @issue.custom_values.find_by_custom_field_id(x.id) || CustomValue.new(:custom_field => x, :customized => @issue) }
    @journals = @issue.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
    @journals.each_with_index {|j,i| j.indice = i+1}
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @activities = Enumeration::get_values('ACTI')
    @priorities = Enumeration::get_values('IPRI')
    respond_to do |format|
      format.html { render :template => 'issues/show.rhtml' }
      format.atom { render :action => 'changes', :layout => false, :content_type => 'application/atom+xml' }
      format.pdf  { send_data(render(:template => 'issues/show.rfpdf', :layout => false), :type => 'application/pdf', :filename => "#{@project.identifier}-#{@issue.id}.pdf") }
    end
  end

  # Add a new issue
  # The new issue will be created from an existing one if copy_from parameter is given
  def new
    @issue = params[:copy_from] ? Issue.new.copy_from(params[:copy_from]) : Issue.new(params[:issue])
    @issue.project = @project
    @issue.author = User.current
    @issue.tracker ||= @project.trackers.find(params[:tracker_id] ? params[:tracker_id] : :first)
    if @issue.tracker.nil?
      flash.now[:error] = 'No tracker is associated to this project. Please check the Project settings.'
      render :nothing => true, :layout => true
      return
    end
    
    default_status = IssueStatus.default
    unless default_status
      flash.now[:error] = 'No default issue status is defined. Please check your configuration (Go to "Administration -> Issue statuses").'
      render :nothing => true, :layout => true
      return
    end    
    @issue.status = default_status
    @allowed_statuses = ([default_status] + default_status.find_new_statuses_allowed_to(User.current.role_for_project(@project), @issue.tracker)).uniq
    
    if request.get? || request.xhr?
      @issue.start_date ||= Date.today
      @custom_values = @issue.custom_values.empty? ?
        @project.custom_fields_for_issues(@issue.tracker).collect { |x| CustomValue.new(:custom_field => x, :customized => @issue) } :
        @issue.custom_values
    else
      requested_status = IssueStatus.find_by_id(params[:issue][:status_id])
      # Check that the user is allowed to apply the requested status
      @issue.status = (@allowed_statuses.include? requested_status) ? requested_status : default_status
      @custom_values = @project.custom_fields_for_issues(@issue.tracker).collect { |x| CustomValue.new(:custom_field => x, :customized => @issue, :value => params["custom_fields"][x.id.to_s]) }
      @issue.custom_values = @custom_values
      if @issue.save
        attach_files(@issue, params[:attachments])
        flash[:notice] = l(:notice_successful_create)
        Mailer.deliver_issue_add(@issue) if Setting.notified_events.include?('issue_added')
        redirect_to :controller => 'issues', :action => 'show', :id => @issue,  :project_id => @project
        return
      end		
    end	
    @priorities = Enumeration::get_values('IPRI')
    render :layout => !request.xhr?
  end
  
  # Attributes that can be updated on workflow transition (without :edit permission)
  # TODO: make it configurable (at least per role)
  UPDATABLE_ATTRS_ON_TRANSITION = %w(status_id assigned_to_id fixed_version_id done_ratio) unless const_defined?(:UPDATABLE_ATTRS_ON_TRANSITION)
  
  def edit
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @activities = Enumeration::get_values('ACTI')
    @priorities = Enumeration::get_values('IPRI')
    @custom_values = []
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    
    @notes = params[:notes]
    journal = @issue.init_journal(User.current, @notes)
    # User can change issue attributes only if he has :edit permission or if a workflow transition is allowed
    if (@edit_allowed || !@allowed_statuses.empty?) && params[:issue]
      attrs = params[:issue].dup
      attrs.delete_if {|k,v| !UPDATABLE_ATTRS_ON_TRANSITION.include?(k) } unless @edit_allowed
      attrs.delete(:status_id) unless @allowed_statuses.detect {|s| s.id.to_s == attrs[:status_id].to_s}
      @issue.attributes = attrs
    end

    if request.get?
      @custom_values = @project.custom_fields_for_issues(@issue.tracker).collect { |x| @issue.custom_values.find_by_custom_field_id(x.id) || CustomValue.new(:custom_field => x, :customized => @issue) }
    else
      # Update custom fields if user has :edit permission
      if @edit_allowed && params[:custom_fields]
        @custom_values = @project.custom_fields_for_issues(@issue.tracker).collect { |x| CustomValue.new(:custom_field => x, :customized => @issue, :value => params["custom_fields"][x.id.to_s]) }
        @issue.custom_values = @custom_values
      end
      attachments = attach_files(@issue, params[:attachments])
      attachments.each {|a| journal.details << JournalDetail.new(:property => 'attachment', :prop_key => a.id, :value => a.filename)}
      if @issue.save
        # Log spend time
        if current_role.allowed_to?(:log_time)
          @time_entry = TimeEntry.new(:project => @project, :issue => @issue, :user => User.current, :spent_on => Date.today)
          @time_entry.attributes = params[:time_entry]
          @time_entry.save
        end
        if !journal.new_record?
          # Only send notification if something was actually changed
          flash[:notice] = l(:notice_successful_update)
          Mailer.deliver_issue_edit(journal) if Setting.notified_events.include?('issue_updated')
        end
        redirect_to(params[:back_to] || {:action => 'show', :id => @issue})
      end
    end
  rescue ActiveRecord::StaleObjectError
    # Optimistic locking exception
    flash.now[:error] = l(:notice_locking_conflict)
  end

  # Bulk edit a set of issues
  def bulk_edit
    if request.post?
      status = params[:status_id].blank? ? nil : IssueStatus.find_by_id(params[:status_id])
      priority = params[:priority_id].blank? ? nil : Enumeration.find_by_id(params[:priority_id])
      assigned_to = (params[:assigned_to_id].blank? || params[:assigned_to_id] == 'none') ? nil : User.find_by_id(params[:assigned_to_id])
      category = (params[:category_id].blank? || params[:category_id] == 'none') ? nil : @project.issue_categories.find_by_id(params[:category_id])
      fixed_version = (params[:fixed_version_id].blank? || params[:fixed_version_id] == 'none') ? nil : @project.versions.find_by_id(params[:fixed_version_id])
      
      unsaved_issue_ids = []      
      @issues.each do |issue|
        journal = issue.init_journal(User.current, params[:notes])
        issue.priority = priority if priority
        issue.assigned_to = assigned_to if assigned_to || params[:assigned_to_id] == 'none'
        issue.category = category if category || params[:category_id] == 'none'
        issue.fixed_version = fixed_version if fixed_version || params[:fixed_version_id] == 'none'
        issue.start_date = params[:start_date] unless params[:start_date].blank?
        issue.due_date = params[:due_date] unless params[:due_date].blank?
        issue.done_ratio = params[:done_ratio] unless params[:done_ratio].blank?
        # Don't save any change to the issue if the user is not authorized to apply the requested status
        if (status.nil? || (issue.status.new_status_allowed_to?(status, current_role, issue.tracker) && issue.status = status)) && issue.save
          # Send notification for each issue (if changed)
          Mailer.deliver_issue_edit(journal) if journal.details.any? && Setting.notified_events.include?('issue_updated')
        else
          # Keep unsaved issue ids to display them in flash error
          unsaved_issue_ids << issue.id
        end
      end
      if unsaved_issue_ids.empty?
        flash[:notice] = l(:notice_successful_update) unless @issues.empty?
      else
        flash[:error] = l(:notice_failed_to_save_issues, unsaved_issue_ids.size, @issues.size, '#' + unsaved_issue_ids.join(', #'))
      end
      redirect_to :controller => 'issues', :action => 'index', :project_id => @project
      return
    end
    # Find potential statuses the user could be allowed to switch issues to
    @available_statuses = Workflow.find(:all, :include => :new_status,
                                              :conditions => {:role_id => current_role.id}).collect(&:new_status).compact.uniq
  end

  def move
    @allowed_projects = []
    # find projects to which the user is allowed to move the issue
    if User.current.admin?
      # admin is allowed to move issues to any active (visible) project
      @allowed_projects = Project.find(:all, :conditions => Project.visible_by(User.current), :order => 'name')
    else
      User.current.memberships.each {|m| @allowed_projects << m.project if m.role.allowed_to?(:move_issues)}
    end
    @target_project = @allowed_projects.detect {|p| p.id.to_s == params[:new_project_id]} if params[:new_project_id]
    @target_project ||= @project    
    @trackers = @target_project.trackers
    if request.post?
      new_tracker = params[:new_tracker_id].blank? ? nil : @target_project.trackers.find_by_id(params[:new_tracker_id])
      unsaved_issue_ids = []
      @issues.each do |issue|
        unsaved_issue_ids << issue.id unless issue.move_to(@target_project, new_tracker)
      end
      if unsaved_issue_ids.empty?
        flash[:notice] = l(:notice_successful_update) unless @issues.empty?
      else
        flash[:error] = l(:notice_failed_to_save_issues, unsaved_issue_ids.size, @issues.size, '#' + unsaved_issue_ids.join(', #'))
      end
      redirect_to :controller => 'issues', :action => 'index', :project_id => @project
      return
    end
    render :layout => false if request.xhr?
  end
  
  def destroy
    @hours = TimeEntry.sum(:hours, :conditions => ['issue_id IN (?)', @issues]).to_f
    if @hours > 0
      case params[:todo]
      when 'destroy'
        # nothing to do
      when 'nullify'
        TimeEntry.update_all('issue_id = NULL', ['issue_id IN (?)', @issues])
      when 'reassign'
        reassign_to = @project.issues.find_by_id(params[:reassign_to_id])
        if reassign_to.nil?
          flash.now[:error] = l(:error_issue_not_found_in_project)
          return
        else
          TimeEntry.update_all("issue_id = #{reassign_to.id}", ['issue_id IN (?)', @issues])
        end
      else
        # display the destroy form
        return
      end
    end
    @issues.each(&:destroy)
    redirect_to :action => 'index', :project_id => @project
  end

  def destroy_attachment
    a = @issue.attachments.find(params[:attachment_id])
    a.destroy
    journal = @issue.init_journal(User.current)
    journal.details << JournalDetail.new(:property => 'attachment',
                                         :prop_key => a.id,
                                         :old_value => a.filename)
    journal.save
    redirect_to :action => 'show', :id => @issue
  end
  
  def context_menu
    @issues = Issue.find_all_by_id(params[:ids], :include => :project)
    if (@issues.size == 1)
      @issue = @issues.first
      @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
      @assignables = @issue.assignable_users
      @assignables << @issue.assigned_to if @issue.assigned_to && !@assignables.include?(@issue.assigned_to)
    end
    projects = @issues.collect(&:project).compact.uniq
    @project = projects.first if projects.size == 1

    @can = {:edit => (@project && User.current.allowed_to?(:edit_issues, @project)),
            :update => (@issue && (User.current.allowed_to?(:edit_issues, @project) || (User.current.allowed_to?(:change_status, @project) && !@allowed_statuses.empty?))),
            :move => (@project && User.current.allowed_to?(:move_issues, @project)),
            :copy => (@issue && @project.trackers.include?(@issue.tracker) && User.current.allowed_to?(:add_issues, @project)),
            :delete => (@project && User.current.allowed_to?(:delete_issues, @project))
            }

    @priorities = Enumeration.get_values('IPRI').reverse
    @statuses = IssueStatus.find(:all, :order => 'position')
    @back = request.env['HTTP_REFERER']
    
    render :layout => false
  end

  def update_form
    @issue = Issue.new(params[:issue])
    render :action => :new, :layout => false
  end
  
  def preview
    issue = @project.issues.find_by_id(params[:id])
    @attachements = issue.attachments if issue
    @text = params[:notes] || (params[:issue] ? params[:issue][:description] : nil)
    render :partial => 'common/preview'
  end
  
private
  def find_issue
    @issue = Issue.find(params[:id], :include => [:project, :tracker, :status, :author, :priority, :category])
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  # Filter for bulk operations
  def find_issues
    @issues = Issue.find_all_by_id(params[:id] || params[:ids])
    raise ActiveRecord::RecordNotFound if @issues.empty?
    projects = @issues.collect(&:project).compact.uniq
    if projects.size == 1
      @project = projects.first
    else
      # TODO: let users bulk edit/move/destroy issues from different projects
      render_error 'Can not bulk edit/move/destroy issues from different projects' and return false
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def find_optional_project
    return true unless params[:project_id]
    @project = Project.find(params[:project_id])
    authorize
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  # Retrieve query from session or build a new query
  def retrieve_query
    if !params[:query_id].blank?
      @query = Query.find(params[:query_id], :conditions => {:project_id => (@project ? @project.id : nil)})
      session[:query] = {:id => @query.id, :project_id => @query.project_id}
    else
      if params[:set_filter] || session[:query].nil? || session[:query][:project_id] != (@project ? @project.id : nil)
        # Give it a name, required to be valid
        @query = Query.new(:name => "_")
        @query.project = @project
        if params[:fields] and params[:fields].is_a? Array
          params[:fields].each do |field|
            @query.add_filter(field, params[:operators][field], params[:values][field])
          end
        else
          @query.available_filters.keys.each do |field|
            @query.add_short_filter(field, params[field]) if params[field]
          end
        end
        session[:query] = {:project_id => @query.project_id, :filters => @query.filters}
      else
        @query = Query.find_by_id(session[:query][:id]) if session[:query][:id]
        @query ||= Query.new(:name => "_", :project => @project, :filters => session[:query][:filters])
      end
    end
  end
end
