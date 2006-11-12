# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

class ProjectsController < ApplicationController
  layout 'base', :except => :export_issues_pdf
  before_filter :find_project, :authorize, :except => [ :index, :list, :add ]
  before_filter :require_admin, :only => [ :add, :destroy ]

  helper :sort
  include SortHelper	
  helper :search_filter
  include SearchFilterHelper	
  helper :custom_fields
  include CustomFieldsHelper   
  helper :ifpdf
  include IfpdfHelper
  
  def index
    list
    render :action => 'list' unless request.xhr?
  end

  # Lists public projects
  def list
    sort_init 'name', 'asc'
    sort_update		
    @project_count = Project.count(["is_public=?", true])		
    @project_pages = Paginator.new self, @project_count,
								15,
								@params['page']								
    @projects = Project.find :all, :order => sort_clause,
						:conditions => ["is_public=?", true],
						:limit  =>  @project_pages.items_per_page,
						:offset =>  @project_pages.current.offset

    render :action => "list", :layout => false if request.xhr?	
  end
          
  # Add a new project
  def add
    @custom_fields = IssueCustomField.find(:all)
    @root_projects = Project.find(:all, :conditions => "parent_id is null")
    @project = Project.new(params[:project])
    if request.get?
      @custom_values = ProjectCustomField.find(:all).collect { |x| CustomValue.new(:custom_field => x, :customized => @project) }
    else
      @project.custom_fields = CustomField.find(@params[:custom_field_ids]) if @params[:custom_field_ids]
      @custom_values = ProjectCustomField.find(:all).collect { |x| CustomValue.new(:custom_field => x, :customized => @project, :value => params["custom_fields"][x.id.to_s]) }
      @project.custom_values = @custom_values			
      if @project.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to :controller => 'admin', :action => 'projects'
	  end		
    end	
  end
	
  # Show @project
  def show
    @custom_values = @project.custom_values.find(:all, :include => :custom_field)
    @members = @project.members.find(:all, :include => [:user, :role])
    @subprojects = @project.children if @project.children_count > 0
    @news = @project.news.find(:all, :limit => 5, :include => [ :author, :project ], :order => "news.created_on DESC")
    @trackers = Tracker.find(:all)
  end

  def settings
    @root_projects = Project::find(:all, :conditions => ["parent_id is null and id <> ?", @project.id])
    @custom_fields = IssueCustomField::find_all
    @issue_category ||= IssueCategory.new
    @member ||= @project.members.new
    @roles = Role.find_all
    @users = User.find_all - @project.members.find(:all, :include => :user).collect{|m| m.user }
    @custom_values ||= ProjectCustomField.find(:all).collect { |x| @project.custom_values.find_by_custom_field_id(x.id) || CustomValue.new(:custom_field => x) }
  end
  
  # Edit @project
  def edit
    if request.post?
      @project.custom_fields = IssueCustomField.find(@params[:custom_field_ids]) if @params[:custom_field_ids]
      if params[:custom_fields]
        @custom_values = ProjectCustomField.find(:all).collect { |x| CustomValue.new(:custom_field => x, :customized => @project, :value => params["custom_fields"][x.id.to_s]) }
        @project.custom_values = @custom_values
      end
      if @project.update_attributes(params[:project])
        flash[:notice] = l(:notice_successful_update)
        redirect_to :action => 'settings', :id => @project
      else
        settings
        render :action => 'settings'
      end
    end
  end

  # Delete @project
  def destroy
    if request.post? and params[:confirm]
      @project.destroy
      redirect_to :controller => 'admin', :action => 'projects'
    end
  end
	
  # Add a new issue category to @project
  def add_issue_category
    if request.post?
      @issue_category = @project.issue_categories.build(params[:issue_category])
      if @issue_category.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to :action => 'settings', :id => @project
      else
        settings
        render :action => 'settings'
      end
    end
  end	
	
  # Add a new version to @project
  def add_version
  	@version = @project.versions.build(params[:version])
  	if request.post? and @version.save
  	  flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'settings', :id => @project
  	end
  end

  # Add a new member to @project
  def add_member
    @member = @project.members.build(params[:member])
  	if request.post?
      if @member.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to :action => 'settings', :id => @project
      else		
        settings
        render :action => 'settings'
      end
    end
  end

  # Show members list of @project
  def list_members
    @members = @project.members
  end

  # Add a new document to @project
  def add_document
    @categories = Enumeration::get_values('DCAT')
    @document = @project.documents.build(params[:document])    
    if request.post?			
      # Save the attachment
      if params[:attachment][:file].size > 0
        @attachment = @document.attachments.build(params[:attachment])				
        @attachment.author_id = self.logged_in_user.id if self.logged_in_user
      end      
      if @document.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to :action => 'list_documents', :id => @project
      end		
    end
  end
  
  # Show documents list of @project
  def list_documents
    @documents = @project.documents
  end

  # Add a new issue to @project
  def add_issue
    @tracker = Tracker.find(params[:tracker_id])
    @priorities = Enumeration::get_values('IPRI')
    @issue = Issue.new(:project => @project, :tracker => @tracker)
    if request.get?
      @issue.start_date = Date.today
      @custom_values = @project.custom_fields_for_issues(@tracker).collect { |x| CustomValue.new(:custom_field => x, :customized => @issue) }
    else
      @issue.attributes = params[:issue]
      @issue.author_id = self.logged_in_user.id if self.logged_in_user
      # Multiple file upload
      params[:attachments].each { |a|
        @attachment = @issue.attachments.build(:file => a, :author => self.logged_in_user) unless a.size == 0
      } if params[:attachments] and params[:attachments].is_a? Array
      @custom_values = @project.custom_fields_for_issues(@tracker).collect { |x| CustomValue.new(:custom_field => x, :customized => @issue, :value => params["custom_fields"][x.id.to_s]) }
      @issue.custom_values = @custom_values			
      if @issue.save
        flash[:notice] = l(:notice_successful_create)
        Mailer.deliver_issue_add(@issue) if Permission.find_by_controller_and_action(@params[:controller], @params[:action]).mail_enabled?
        redirect_to :action => 'list_issues', :id => @project
      end		
    end	
  end

  # Show filtered/sorted issues list of @project
  def list_issues
    sort_init 'issues.id', 'desc'
    sort_update

    search_filter_init_list_issues
    search_filter_update if params[:set_filter]

    @results_per_page_options = [ 15, 25, 50, 100 ]
    if params[:per_page] and @results_per_page_options.include? params[:per_page].to_i
      @results_per_page = params[:per_page].to_i
      session[:results_per_page] = @results_per_page
    else
      @results_per_page = session[:results_per_page] || 25
    end

    @issue_count = Issue.count(:include => [:status, :project], :conditions => search_filter_clause)		
    @issue_pages = Paginator.new self, @issue_count, @results_per_page, @params['page']								
    @issues = Issue.find :all, :order => sort_clause,
						:include => [ :author, :status, :tracker, :project ],
						:conditions => search_filter_clause,
						:limit  =>  @issue_pages.items_per_page,
						:offset =>  @issue_pages.current.offset						
    
    render :layout => false if request.xhr?
  end

  # Export filtered/sorted issues list to CSV
  def export_issues_csv
    sort_init 'issues.id', 'desc'
    sort_update

    search_filter_init_list_issues
					
    @issues =  Issue.find :all, :order => sort_clause,
						:include => [ :author, :status, :tracker, :project, :custom_values ],
						:conditions => search_filter_clause							

    ic = Iconv.new('ISO-8859-1', 'UTF-8')    
    export = StringIO.new
    CSV::Writer.generate(export, l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [ "#", l(:field_status), l(:field_tracker), l(:field_subject), l(:field_author), l(:field_created_on), l(:field_updated_on) ]
      for custom_field in @project.all_custom_fields
        headers << custom_field.name
      end      
      csv << headers.collect {|c| ic.iconv(c) }
      # csv lines
      @issues.each do |issue|
        fields = [issue.id, issue.status.name, issue.tracker.name, issue.subject, issue.author.display_name, l_datetime(issue.created_on),  l_datetime(issue.updated_on)]
        for custom_field in @project.all_custom_fields
          fields << (show_value issue.custom_value_for(custom_field))
        end
        csv << fields.collect {|c| ic.iconv(c.to_s) }
      end
    end
    export.rewind
    send_data(export.read, :type => 'text/csv; header=present', :filename => 'export.csv')
  end
  
  # Export filtered/sorted issues to PDF
  def export_issues_pdf
    sort_init 'issues.id', 'desc'
    sort_update

    search_filter_init_list_issues
					
    @issues =  Issue.find :all, :order => sort_clause,
						:include => [ :author, :status, :tracker, :project, :custom_values ],
						:conditions => search_filter_clause
											
    @options_for_rfpdf ||= {}
    @options_for_rfpdf[:file_name] = "export.pdf"
  end

  def move_issues
    @issues = @project.issues.find(params[:issue_ids]) if params[:issue_ids]
    redirect_to :action => 'list_issues', :id => @project and return unless @issues
    @projects = []
    # find projects to which the user is allowed to move the issue
    @logged_in_user.memberships.each {|m| @projects << m.project if Permission.allowed_to_role("projects/move_issues", m.role_id)}
    # issue can be moved to any tracker
    @trackers = Tracker.find(:all)
    if request.post? and params[:new_project_id] and params[:new_tracker_id]    
      new_project = Project.find(params[:new_project_id])
      new_tracker = Tracker.find(params[:new_tracker_id])
      @issues.each { |i|
        # category is project dependent
        i.category = nil unless i.project_id == new_project.id
        # move the issue
        i.project = new_project
        i.tracker = new_tracker
        i.save
      }
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'list_issues', :id => @project
    end
  end

  # Add a news to @project
  def add_news
    @news = News.new(:project => @project)
    if request.post?
      @news.attributes = params[:news]
      @news.author_id = self.logged_in_user.id if self.logged_in_user
      if @news.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to :action => 'list_news', :id => @project
      end
    end
  end

  # Show news list of @project
  def list_news
    @news_pages, @news = paginate :news, :per_page => 10, :conditions => ["project_id=?", @project.id], :include => :author, :order => "news.created_on DESC"
    render :action => "list_news", :layout => false if request.xhr?
  end

  def add_file  
    if request.post?
      # Save the attachment
      if params[:attachment][:file].size > 0
        @attachment = @project.versions.find(params[:version_id]).attachments.build(params[:attachment])      
        @attachment.author_id = self.logged_in_user.id if self.logged_in_user
        if @attachment.save
          flash[:notice] = l(:notice_successful_create)
          redirect_to :controller => 'projects', :action => 'list_files', :id => @project
        end
      end
    end
    @versions = @project.versions
  end
  
  def list_files
    @versions = @project.versions
  end
  
  # Show changelog for @project
  def changelog
    @trackers = Tracker.find(:all, :conditions => ["is_in_chlog=?", true])
    if request.get?
      @selected_tracker_ids = @trackers.collect {|t| t.id.to_s }
    else
      @selected_tracker_ids = params[:tracker_ids].collect { |id| id.to_i.to_s } if params[:tracker_ids] and params[:tracker_ids].is_a? Array
    end
    @selected_tracker_ids ||= []
    @fixed_issues = @project.issues.find(:all, 
      :include => [ :fixed_version, :status, :tracker ], 
      :conditions => [ "issue_statuses.is_closed=? and issues.tracker_id in (#{@selected_tracker_ids.join(',')}) and issues.fixed_version_id is not null", true],
      :order => "versions.effective_date DESC, issues.id DESC"
    ) unless @selected_tracker_ids.empty?
    @fixed_issues ||= []
  end

  def activity
    if params[:year] and params[:year].to_i > 1900
      @year = params[:year].to_i
      if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
        @month = params[:month].to_i
      end    
    end
    @year ||= Date.today.year
    @month ||= Date.today.month

    @date_from = Date.civil(@year, @month, 1)
    @date_to = (@date_from >> 1)-1
    
    @events_by_day = {}    
    
    unless params[:show_issues] == "0"
      @project.issues.find(:all, :include => [:author, :status], :conditions => ["issues.created_on>=? and issues.created_on<=?", @date_from, @date_to] ).each { |i|
        @events_by_day[i.created_on.to_date] ||= []
        @events_by_day[i.created_on.to_date] << i
      }
      @show_issues = 1
    end
    
    unless params[:show_news] == "0"
      @project.news.find(:all, :conditions => ["news.created_on>=? and news.created_on<=?", @date_from, @date_to] ).each { |i|
        @events_by_day[i.created_on.to_date] ||= []
        @events_by_day[i.created_on.to_date] << i
      }
      @show_news = 1 
    end
    
    unless params[:show_files] == "0"
      Attachment.find(:all, :joins => "LEFT JOIN versions ON versions.id = attachments.container_id", :conditions => ["attachments.container_type='Version' and versions.project_id=? and attachments.created_on>=? and attachments.created_on<=?", @project.id, @date_from, @date_to] ).each { |i|
        @events_by_day[i.created_on.to_date] ||= []
        @events_by_day[i.created_on.to_date] << i
      }
      @show_files = 1 
    end
    
    unless params[:show_documentss] == "0"
      Attachment.find(:all, :joins => "LEFT JOIN documents ON documents.id = attachments.container_id", :conditions => ["attachments.container_type='Document' and documents.project_id=? and attachments.created_on>=? and attachments.created_on<=?", @project.id, @date_from, @date_to] ).each { |i|
        @events_by_day[i.created_on.to_date] ||= []
        @events_by_day[i.created_on.to_date] << i
      }
      @show_documents = 1 
    end

  end
  
  def calendar
    if params[:year] and params[:year].to_i > 1900
      @year = params[:year].to_i
      if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
        @month = params[:month].to_i
      end    
    end
    @year ||= Date.today.year
    @month ||= Date.today.month
    
    @date_from = Date.civil(@year, @month, 1)
    @date_to = (@date_from >> 1)-1
    # start on monday
    @date_from = @date_from - (@date_from.cwday-1)
    # finish on sunday
    @date_to = @date_to + (7-@date_to.cwday)  
      
    @issues = @project.issues.find(:all, :include => :tracker, :conditions => ["((start_date>=? and start_date<=?) or (due_date>=? and due_date<=?))", @date_from, @date_to, @date_from, @date_to])
    render :layout => false if request.xhr?
  end  

  def gantt
    if params[:year] and params[:year].to_i >0
      @year_from = params[:year].to_i
      if params[:month] and params[:month].to_i >=1 and params[:month].to_i <= 12
        @month_from = params[:month].to_i
      else
        @month_from = 1
      end
    else
      @month_from ||= (Date.today << 1).month
      @year_from ||= (Date.today << 1).year
    end
    
    @zoom = (params[:zoom].to_i > 0 and params[:zoom].to_i < 5) ? params[:zoom].to_i : 2
    @months = (params[:months].to_i > 0 and params[:months].to_i < 25) ? params[:months].to_i : 6
    
    @date_from = Date.civil(@year_from, @month_from, 1)
    @date_to = (@date_from >> @months) - 1
    @issues = @project.issues.find(:all, :order => "start_date, due_date", :conditions => ["(((start_date>=? and start_date<=?) or (due_date>=? and due_date<=?) or (start_date<? and due_date>?)) and start_date is not null and due_date is not null)", @date_from, @date_to, @date_from, @date_to, @date_from, @date_to])
    
    if params[:output]=='pdf'
      @options_for_rfpdf ||= {}
      @options_for_rfpdf[:file_name] = "gantt.pdf"
      render :template => "projects/gantt.rfpdf", :layout => false
    else
      render :template => "projects/gantt.rhtml"
    end
  end
  
private
  # Find project of id params[:id]
  # if not found, redirect to project list
  # Used as a before_filter
  def find_project
    @project = Project.find(params[:id])
    @html_title = @project.name
  rescue
    redirect_to :action => 'list'			
  end
end
