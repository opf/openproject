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
  before_filter :find_project, :authorize, :except => [:index, :changes, :preview]
  before_filter :find_optional_project, :only => [:index, :changes]
  accept_key_auth :index, :changes
  
  cache_sweeper :issue_sweeper, :only => [ :edit, :change_status, :destroy ]

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
      limit = %w(pdf csv).include?(params[:format]) ? Setting.issues_export_limit.to_i : 25
      @issue_count = Issue.count(:include => [:status, :project], :conditions => @query.statement)
      @issue_pages = Paginator.new self, @issue_count, limit, params['page']
      @issues = Issue.find :all, :order => sort_clause,
                           :include => [ :assigned_to, :status, :tracker, :project, :priority, :category ],
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
      @changes = Journal.find :all, :include => [ :details, :user, {:issue => [:project, :author, :tracker, :status]} ],
                                     :conditions => @query.statement,
                                     :limit => 25,
                                     :order => "#{Journal.table_name}.created_on DESC"
    end
    @title = (@project ? @project.name : Setting.app_title) + ": " + (@query.new_record? ? l(:label_changes_details) : @query.name)
    render :layout => false, :content_type => 'application/atom+xml'
  end
  
  def show
    @custom_values = @issue.custom_values.find(:all, :include => :custom_field, :order => "#{CustomField.table_name}.position")
    @journals = @issue.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
    @status_options = @issue.status.find_new_statuses_allowed_to(logged_in_user.role_for_project(@project), @issue.tracker) if logged_in_user
    respond_to do |format|
      format.html { render :template => 'issues/show.rhtml' }
      format.pdf  { send_data(render(:template => 'issues/show.rfpdf', :layout => false), :type => 'application/pdf', :filename => "#{@project.identifier}-#{@issue.id}.pdf") }
    end
  end

  def edit
    @priorities = Enumeration::get_values('IPRI')
    if request.get?
      @custom_values = @project.custom_fields_for_issues(@issue.tracker).collect { |x| @issue.custom_values.find_by_custom_field_id(x.id) || CustomValue.new(:custom_field => x, :customized => @issue) }
    else
      begin
        @issue.init_journal(self.logged_in_user)
        # Retrieve custom fields and values
        if params["custom_fields"]
          @custom_values = @project.custom_fields_for_issues(@issue.tracker).collect { |x| CustomValue.new(:custom_field => x, :customized => @issue, :value => params["custom_fields"][x.id.to_s]) }
          @issue.custom_values = @custom_values
        end
        @issue.attributes = params[:issue]
        if @issue.save
          flash[:notice] = l(:notice_successful_update)
          redirect_to(params[:back_to] || {:action => 'show', :id => @issue})
        end
      rescue ActiveRecord::StaleObjectError
        # Optimistic locking exception
        flash[:error] = l(:notice_locking_conflict)
      end
    end		
  end
  
  def add_note
    journal = @issue.init_journal(User.current, params[:notes])
    params[:attachments].each { |file|
      next unless file.size > 0
      a = Attachment.create(:container => @issue, :file => file, :author => logged_in_user)
      journal.details << JournalDetail.new(:property => 'attachment',
                                           :prop_key => a.id,
                                           :value => a.filename) unless a.new_record?
    } if params[:attachments] and params[:attachments].is_a? Array
    if journal.save
      flash[:notice] = l(:notice_successful_update)
      Mailer.deliver_issue_edit(journal) if Setting.notified_events.include?('issue_updated')
      redirect_to :action => 'show', :id => @issue
      return
    end
    show
  end

  def change_status
    @status_options = @issue.status.find_new_statuses_allowed_to(logged_in_user.role_for_project(@project), @issue.tracker) if logged_in_user
    @new_status = IssueStatus.find(params[:new_status_id])
    if params[:confirm]
      begin
        journal = @issue.init_journal(self.logged_in_user, params[:notes])
        @issue.status = @new_status
        if @issue.update_attributes(params[:issue])
          # Save attachments
          params[:attachments].each { |file|
            next unless file.size > 0
            a = Attachment.create(:container => @issue, :file => file, :author => logged_in_user)            
            journal.details << JournalDetail.new(:property => 'attachment',
                                                 :prop_key => a.id,
                                                 :value => a.filename) unless a.new_record?
          } if params[:attachments] and params[:attachments].is_a? Array
        
          # Log time
          if current_role.allowed_to?(:log_time)
            @time_entry ||= TimeEntry.new(:project => @project, :issue => @issue, :user => logged_in_user, :spent_on => Date.today)
            @time_entry.attributes = params[:time_entry]
            @time_entry.save
          end
          
          flash[:notice] = l(:notice_successful_update)
          Mailer.deliver_issue_edit(journal) if Setting.notified_events.include?('issue_updated')
          redirect_to :action => 'show', :id => @issue
        end
      rescue ActiveRecord::StaleObjectError
        # Optimistic locking exception
        flash[:error] = l(:notice_locking_conflict)
      end
    end    
    @assignable_to = @project.members.find(:all, :include => :user).collect{ |m| m.user }
    @activities = Enumeration::get_values('ACTI')
  end

  def destroy
    @issue.destroy
    redirect_to :action => 'index', :project_id => @project
  end

  def destroy_attachment
    a = @issue.attachments.find(params[:attachment_id])
    a.destroy
    journal = @issue.init_journal(self.logged_in_user)
    journal.details << JournalDetail.new(:property => 'attachment',
                                         :prop_key => a.id,
                                         :old_value => a.filename)
    journal.save
    redirect_to :action => 'show', :id => @issue
  end
  
  def context_menu
    @priorities = Enumeration.get_values('IPRI').reverse
    @statuses = IssueStatus.find(:all, :order => 'position')
    @allowed_statuses = @issue.status.find_new_statuses_allowed_to(User.current.role_for_project(@project), @issue.tracker)
    @assignables = @issue.assignable_users
    @assignables << @issue.assigned_to if @issue.assigned_to && !@assignables.include?(@issue.assigned_to)
    @can = {:edit => User.current.allowed_to?(:edit_issues, @project),
            :change_status => User.current.allowed_to?(:change_issue_status, @project),
            :add => User.current.allowed_to?(:add_issues, @project),
            :move => User.current.allowed_to?(:move_issues, @project),
            :delete => User.current.allowed_to?(:delete_issues, @project)}
    render :layout => false
  end

  def preview
    issue = Issue.find_by_id(params[:id])
    @attachements = issue.attachments if issue
    @text = params[:issue][:description]
    render :partial => 'common/preview'
  end
  
private
  def find_project
    @issue = Issue.find(params[:id], :include => [:project, :tracker, :status, :author, :priority, :category])
    @project = @issue.project
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
    if params[:query_id]
      @query = Query.find(params[:query_id], :conditions => {:project_id => (@project ? @project.id : nil)})
      @query.executed_by = logged_in_user
      session[:query] = @query
    else
      if params[:set_filter] or !session[:query] or session[:query].project != @project
        # Give it a name, required to be valid
        @query = Query.new(:name => "_", :executed_by => logged_in_user)
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
        session[:query] = @query
      else
        @query = session[:query]
      end
    end
  end
end
