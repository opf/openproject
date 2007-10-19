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
  layout 'base', :except => :export_pdf
  before_filter :find_project, :authorize, :except => [:index, :preview]
  accept_key_auth :index
  
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

  def index
    sort_init "#{Issue.table_name}.id", "desc"
    sort_update
    retrieve_query
    if @query.valid?
      @issue_count = Issue.count(:include => [:status, :project], :conditions => @query.statement)		
      @issue_pages = Paginator.new self, @issue_count, 25, params['page']								
      @issues = Issue.find :all, :order => sort_clause,
                           :include => [ :assigned_to, :status, :tracker, :project, :priority, :category ],
                           :conditions => @query.statement,
                           :limit  =>  @issue_pages.items_per_page,
                           :offset =>  @issue_pages.current.offset						
    end
    respond_to do |format|
      format.html { render :layout => false if request.xhr? }
      format.atom { render_feed(@issues, :title => l(:label_issue_plural)) }
    end
  end
  
  def show
    @custom_values = @issue.custom_values.find(:all, :include => :custom_field)
    @journals = @issue.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")

    if params[:format]=='pdf'
      @options_for_rfpdf ||= {}
      @options_for_rfpdf[:file_name] = "#{@project.identifier}-#{@issue.id}.pdf"
      render :template => 'issues/show.rfpdf', :layout => false
    else
      @status_options = @issue.status.find_new_statuses_allowed_to(logged_in_user.role_for_project(@project), @issue.tracker) if logged_in_user
      render :template => 'issues/show.rhtml'
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
        @custom_values = @project.custom_fields_for_issues(@issue.tracker).collect { |x| CustomValue.new(:custom_field => x, :customized => @issue, :value => params["custom_fields"][x.id.to_s]) }
        @issue.custom_values = @custom_values
        @issue.attributes = params[:issue]
        if @issue.save
          flash[:notice] = l(:notice_successful_update)
          redirect_to :action => 'show', :id => @issue
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
    redirect_to :controller => 'projects', :action => 'list_issues', :id => @project
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
  
  # Retrieve query from session or build a new query
  def retrieve_query
    if params[:set_filter] or !session[:query] or session[:query].project_id
      # Give it a name, required to be valid
      @query = Query.new(:name => "_", :executed_by => logged_in_user)
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
