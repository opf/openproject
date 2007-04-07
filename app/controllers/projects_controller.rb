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

require 'csv'

class ProjectsController < ApplicationController
  layout 'base'
  before_filter :find_project, :authorize, :except => [ :index, :list, :add ]
  before_filter :require_admin, :only => [ :add, :destroy ]

  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper   
  helper :ifpdf
  include IfpdfHelper
  helper IssuesHelper
  helper :queries
  include QueriesHelper
  
  def index
    list
    render :action => 'list' unless request.xhr?
  end

  # Lists public projects
  def list
    sort_init "#{Project.table_name}.name", "asc"
    sort_update		
    @project_count = Project.count(:all, :conditions => ["is_public=?", true])		
    @project_pages = Paginator.new self, @project_count,
								15,
								params['page']								
    @projects = Project.find :all, :order => sort_clause,
						:conditions => ["#{Project.table_name}.is_public=?", true],
						:include => :parent,
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
      @project.custom_fields = CustomField.find(params[:custom_field_ids]) if params[:custom_field_ids]
      @custom_values = ProjectCustomField.find(:all).collect { |x| CustomValue.new(:custom_field => x, :customized => @project, :value => params["custom_fields"][x.id.to_s]) }
      @project.custom_values = @custom_values			
      if params[:repository_enabled] && params[:repository_enabled] == "1"
        @project.repository = Repository.new
        @project.repository.attributes = params[:repository]
      end
      if "1" == params[:wiki_enabled]
        @project.wiki = Wiki.new
        @project.wiki.attributes = params[:wiki]
      end
      if @project.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to :controller => 'admin', :action => 'projects'
	  end		
    end	
  end
	
  # Show @project
  def show
    @custom_values = @project.custom_values.find(:all, :include => :custom_field)
    @members = @project.members.find(:all, :include => [:user, :role], :order => 'position')
    @subprojects = @project.children if @project.children.size > 0
    @news = @project.news.find(:all, :limit => 5, :include => [ :author, :project ], :order => "#{News.table_name}.created_on DESC")
    @trackers = Tracker.find(:all, :order => 'position')
    @open_issues_by_tracker = Issue.count(:group => :tracker, :joins => "INNER JOIN #{IssueStatus.table_name} ON #{IssueStatus.table_name}.id = #{Issue.table_name}.status_id", :conditions => ["project_id=? and #{IssueStatus.table_name}.is_closed=?", @project.id, false])
    @total_issues_by_tracker = Issue.count(:group => :tracker, :conditions => ["project_id=?", @project.id])
  end

  def settings
    @root_projects = Project::find(:all, :conditions => ["parent_id is null and id <> ?", @project.id])
    @custom_fields = IssueCustomField.find(:all)
    @issue_category ||= IssueCategory.new
    @member ||= @project.members.new
    @roles = Role.find(:all, :order => 'position')
    @users = User.find_active(:all) - @project.users
    @custom_values ||= ProjectCustomField.find(:all).collect { |x| @project.custom_values.find_by_custom_field_id(x.id) || CustomValue.new(:custom_field => x) }
  end
  
  # Edit @project
  def edit
    if request.post?
      @project.custom_fields = IssueCustomField.find(params[:custom_field_ids]) if params[:custom_field_ids]
      if params[:custom_fields]
        @custom_values = ProjectCustomField.find(:all).collect { |x| CustomValue.new(:custom_field => x, :customized => @project, :value => params["custom_fields"][x.id.to_s]) }
        @project.custom_values = @custom_values
      end
      if params[:repository_enabled]
        case params[:repository_enabled]
        when "0"
          @project.repository = nil
        when "1"
          @project.repository ||= Repository.new
          @project.repository.update_attributes params[:repository]
        end
      end
      if params[:wiki_enabled]
        case params[:wiki_enabled]
        when "0"
          @project.wiki.destroy if @project.wiki
        when "1"
          @project.wiki ||= Wiki.new
          @project.wiki.update_attributes params[:wiki]
        end
      end      
      @project.attributes = params[:project]
      if @project.save
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
        redirect_to :action => 'settings', :tab => 'categories', :id => @project
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
      redirect_to :action => 'settings', :tab => 'versions', :id => @project
  	end
  end

  # Add a new member to @project
  def add_member
    @member = @project.members.build(params[:member])
  	if request.post?
      if @member.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to :action => 'settings', :tab => 'members', :id => @project
      else		
        settings
        render :action => 'settings'
      end
    end
  end

  # Show members list of @project
  def list_members
    @members = @project.members.find(:all)
  end

  # Add a new document to @project
  def add_document
    @categories = Enumeration::get_values('DCAT')
    @document = @project.documents.build(params[:document])    
    if request.post? and @document.save	
      # Save the attachments
      params[:attachments].each { |a|
        Attachment.create(:container => @document, :file => a, :author => logged_in_user) unless a.size == 0
      } if params[:attachments] and params[:attachments].is_a? Array
      flash[:notice] = l(:notice_successful_create)
      Mailer.deliver_document_add(@document) if Permission.find_by_controller_and_action(params[:controller], params[:action]).mail_enabled?
      redirect_to :action => 'list_documents', :id => @project
    end
  end
  
  # Show documents list of @project
  def list_documents
    @documents = @project.documents.find :all, :include => :category
  end

  # Add a new issue to @project
  def add_issue
    @tracker = Tracker.find(params[:tracker_id])
    @priorities = Enumeration::get_values('IPRI')
    
    default_status = IssueStatus.default
    @issue = Issue.new(:project => @project, :tracker => @tracker)    
    @issue.status = default_status
    @allowed_statuses = default_status.find_new_statuses_allowed_to(logged_in_user.role_for_project(@project), @issue.tracker) if logged_in_user
    if request.get?
      @issue.start_date = Date.today
      @custom_values = @project.custom_fields_for_issues(@tracker).collect { |x| CustomValue.new(:custom_field => x, :customized => @issue) }
    else
      @issue.attributes = params[:issue]
      
      requested_status = IssueStatus.find_by_id(params[:issue][:status_id])
      @issue.status = (@allowed_statuses.include? requested_status) ? requested_status : default_status
      
      @issue.author_id = self.logged_in_user.id if self.logged_in_user
      # Multiple file upload
      @attachments = []
      params[:attachments].each { |a|
        @attachments << Attachment.new(:container => @issue, :file => a, :author => logged_in_user) unless a.size == 0
      } if params[:attachments] and params[:attachments].is_a? Array
      @custom_values = @project.custom_fields_for_issues(@tracker).collect { |x| CustomValue.new(:custom_field => x, :customized => @issue, :value => params["custom_fields"][x.id.to_s]) }
      @issue.custom_values = @custom_values
      if @issue.save
        @attachments.each(&:save)
        flash[:notice] = l(:notice_successful_create)
        Mailer.deliver_issue_add(@issue) if Permission.find_by_controller_and_action(params[:controller], params[:action]).mail_enabled?
        redirect_to :action => 'list_issues', :id => @project
      end		
    end	
  end

  # Show filtered/sorted issues list of @project
  def list_issues
    sort_init "#{Issue.table_name}.id", "desc"
    sort_update

    retrieve_query

    @results_per_page_options = [ 15, 25, 50, 100 ]
    if params[:per_page] and @results_per_page_options.include? params[:per_page].to_i
      @results_per_page = params[:per_page].to_i
      session[:results_per_page] = @results_per_page
    else
      @results_per_page = session[:results_per_page] || 25
    end

    if @query.valid?
      @issue_count = Issue.count(:include => [:status, :project], :conditions => @query.statement)		
      @issue_pages = Paginator.new self, @issue_count, @results_per_page, params['page']								
      @issues = Issue.find :all, :order => sort_clause,
  						:include => [ :assigned_to, :status, :tracker, :project, :priority ],
  						:conditions => @query.statement,
  						:limit  =>  @issue_pages.items_per_page,
  						:offset =>  @issue_pages.current.offset						
    end    
    @trackers = Tracker.find :all, :order => 'position'
    render :layout => false if request.xhr?
  end

  # Export filtered/sorted issues list to CSV
  def export_issues_csv
    sort_init "#{Issue.table_name}.id", "desc"
    sort_update

    retrieve_query
    render :action => 'list_issues' and return unless @query.valid?
					
    @issues =  Issue.find :all, :order => sort_clause,
						:include => [ :assigned_to, :author, :status, :tracker, :priority, {:custom_values => :custom_field} ],
						:conditions => @query.statement,
						:limit => Setting.issues_export_limit

    ic = Iconv.new(l(:general_csv_encoding), 'UTF-8')    
    export = StringIO.new
    CSV::Writer.generate(export, l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [ "#", l(:field_status), 
                       l(:field_tracker),
                       l(:field_priority),
                       l(:field_subject),
                       l(:field_assigned_to),
                       l(:field_author),
                       l(:field_start_date),
                       l(:field_due_date),
                       l(:field_done_ratio),
                       l(:field_created_on),
                       l(:field_updated_on)
                       ]
      for custom_field in @project.all_custom_fields
        headers << custom_field.name
      end      
      csv << headers.collect {|c| ic.iconv(c) }
      # csv lines
      @issues.each do |issue|
        fields = [issue.id, issue.status.name, 
                            issue.tracker.name, 
                            issue.priority.name,
                            issue.subject, 
                            (issue.assigned_to ? issue.assigned_to.name : ""),
                            issue.author.name,
                            issue.start_date ? l_date(issue.start_date) : nil,
                            issue.due_date ? l_date(issue.due_date) : nil,
                            issue.done_ratio,
                            l_datetime(issue.created_on),  
                            l_datetime(issue.updated_on)
                            ]
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
    sort_init "#{Issue.table_name}.id", "desc"
    sort_update

    retrieve_query
    render :action => 'list_issues' and return unless @query.valid?
					
    @issues =  Issue.find :all, :order => sort_clause,
						:include => [ :author, :status, :tracker, :priority ],
						:conditions => @query.statement,
						:limit => Setting.issues_export_limit
											
    @options_for_rfpdf ||= {}
    @options_for_rfpdf[:file_name] = "export.pdf"
    render :layout => false
  end

  def move_issues
    @issues = @project.issues.find(params[:issue_ids]) if params[:issue_ids]
    redirect_to :action => 'list_issues', :id => @project and return unless @issues
    @projects = []
    # find projects to which the user is allowed to move the issue
    @logged_in_user.memberships.each {|m| @projects << m.project if Permission.allowed_to_role("projects/move_issues", m.role)}
    # issue can be moved to any tracker
    @trackers = Tracker.find(:all)
    if request.post? and params[:new_project_id] and params[:new_tracker_id]    
      new_project = Project.find(params[:new_project_id])
      new_tracker = Tracker.find(params[:new_tracker_id])
      @issues.each { |i|
        # project dependent properties
        unless i.project_id == new_project.id
          i.category = nil 
          i.fixed_version = nil
        end
        # move the issue
        i.project = new_project
        i.tracker = new_tracker
        i.save
      }
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'list_issues', :id => @project
    end
  end

  def add_query
    @query = Query.new(params[:query])
    @query.project = @project
    @query.user = logged_in_user
    
    params[:fields].each do |field|
      @query.add_filter(field, params[:operators][field], params[:values][field])
    end if params[:fields]
    
    if request.post? and @query.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :controller => 'reports', :action => 'issue_report', :id => @project
    end    
    render :layout => false if request.xhr?
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
    @news_pages, @news = paginate :news, :per_page => 10, :conditions => ["project_id=?", @project.id], :include => :author, :order => "#{News.table_name}.created_on DESC"
    render :action => "list_news", :layout => false if request.xhr?
  end

  def add_file
    if request.post?
      @version = @project.versions.find_by_id(params[:version_id])
      # Save the attachments
      @attachments = []
      params[:attachments].each { |file|
        next unless file.size > 0
        a = Attachment.create(:container => @version, :file => file, :author => logged_in_user)
        @attachments << a unless a.new_record?
      } if params[:attachments] and params[:attachments].is_a? Array
      Mailer.deliver_attachments_add(@attachments) if !@attachments.empty? and Permission.find_by_controller_and_action(params[:controller], params[:action]).mail_enabled?
      redirect_to :controller => 'projects', :action => 'list_files', :id => @project
    end
    @versions = @project.versions
  end
  
  def list_files
    @versions = @project.versions
  end
  
  # Show changelog for @project
  def changelog
    @trackers = Tracker.find(:all, :conditions => ["is_in_chlog=?", true], :order => 'position')
    retrieve_selected_tracker_ids(@trackers)
    
    @fixed_issues = @project.issues.find(:all, 
      :include => [ :fixed_version, :status, :tracker ], 
      :conditions => [ "#{IssueStatus.table_name}.is_closed=? and #{Issue.table_name}.tracker_id in (#{@selected_tracker_ids.join(',')}) and #{Issue.table_name}.fixed_version_id is not null", true],
      :order => "#{Version.table_name}.effective_date DESC, #{Issue.table_name}.id DESC"
    ) unless @selected_tracker_ids.empty?
    @fixed_issues ||= []
  end

  def roadmap
    @trackers = Tracker.find(:all, :conditions => ["is_in_roadmap=?", true], :order => 'position')
    retrieve_selected_tracker_ids(@trackers)
    
    @versions = @project.versions.find(:all,
      :conditions => [ "#{Version.table_name}.effective_date>?", Date.today],
      :order => "#{Version.table_name}.effective_date ASC"
    )
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
      @project.issues.find(:all, :include => [:author], :conditions => ["#{Issue.table_name}.created_on>=? and #{Issue.table_name}.created_on<=?", @date_from, @date_to] ).each { |i|
        @events_by_day[i.created_on.to_date] ||= []
        @events_by_day[i.created_on.to_date] << i
      }
      @show_issues = 1
    end
    
    unless params[:show_news] == "0"
      @project.news.find(:all, :conditions => ["#{News.table_name}.created_on>=? and #{News.table_name}.created_on<=?", @date_from, @date_to], :include => :author ).each { |i|
        @events_by_day[i.created_on.to_date] ||= []
        @events_by_day[i.created_on.to_date] << i
      }
      @show_news = 1 
    end
    
    unless params[:show_files] == "0"
      Attachment.find(:all, :select => "#{Attachment.table_name}.*", :joins => "LEFT JOIN #{Version.table_name} ON #{Version.table_name}.id = #{Attachment.table_name}.container_id", :conditions => ["#{Attachment.table_name}.container_type='Version' and #{Version.table_name}.project_id=? and #{Attachment.table_name}.created_on>=? and #{Attachment.table_name}.created_on<=?", @project.id, @date_from, @date_to], :include => :author ).each { |i|
        @events_by_day[i.created_on.to_date] ||= []
        @events_by_day[i.created_on.to_date] << i
      }
      @show_files = 1 
    end
    
    unless params[:show_documents] == "0"
      @project.documents.find(:all, :conditions => ["#{Document.table_name}.created_on>=? and #{Document.table_name}.created_on<=?", @date_from, @date_to] ).each { |i|
        @events_by_day[i.created_on.to_date] ||= []
        @events_by_day[i.created_on.to_date] << i
      }
      Attachment.find(:all, :select => "attachments.*", :joins => "LEFT JOIN #{Document.table_name} ON #{Document.table_name}.id = #{Attachment.table_name}.container_id", :conditions => ["#{Attachment.table_name}.container_type='Document' and #{Document.table_name}.project_id=? and #{Attachment.table_name}.created_on>=? and #{Attachment.table_name}.created_on<=?", @project.id, @date_from, @date_to], :include => :author ).each { |i|
        @events_by_day[i.created_on.to_date] ||= []
        @events_by_day[i.created_on.to_date] << i
      }
      @show_documents = 1 
    end
    
    unless params[:show_wiki_edits] == "0"
      select = "#{WikiContent.versioned_table_name}.updated_on, #{WikiContent.versioned_table_name}.comment, " +
               "#{WikiContent.versioned_table_name}.#{WikiContent.version_column}, #{WikiPage.table_name}.title"
      joins = "LEFT JOIN #{WikiPage.table_name} ON #{WikiPage.table_name}.id = #{WikiContent.versioned_table_name}.page_id " +
              "LEFT JOIN #{Wiki.table_name} ON #{Wiki.table_name}.id = #{WikiPage.table_name}.wiki_id "
      conditions = ["#{Wiki.table_name}.project_id = ? AND #{WikiContent.versioned_table_name}.updated_on BETWEEN ? AND ?",
                    @project.id, @date_from, @date_to]

      WikiContent.versioned_class.find(:all, :select => select, :joins => joins, :conditions => conditions).each { |i|
        # We provide this alias so all events can be treated in the same manner
        def i.created_on
          self.updated_on
        end

        @events_by_day[i.created_on.to_date] ||= []
        @events_by_day[i.created_on.to_date] << i
      }
      @show_wiki_edits = 1
    end

    unless @project.repository.nil? || params[:show_changesets] == "0"
      @project.repository.changesets.find(:all, :conditions => ["#{Changeset.table_name}.committed_on BETWEEN ? AND ?", @date_from, @date_to]).each { |i|
        def i.created_on
          self.committed_on
        end
        @events_by_day[i.created_on.to_date] ||= []
        @events_by_day[i.created_on.to_date] << i
      }
      @show_changesets = 1 
    end
    
    render :layout => false if request.xhr?
  end
  
  def calendar
    @trackers = Tracker.find(:all, :order => 'position')
    retrieve_selected_tracker_ids(@trackers)
    
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
    
    @events = []
    @project.issues_with_subprojects(params[:with_subprojects]) do
      @events += Issue.find(:all, 
                           :include => [:tracker, :status, :assigned_to, :priority], 
                           :conditions => ["((start_date>=? and start_date<=?) or (due_date>=? and due_date<=?)) and #{Issue.table_name}.tracker_id in (#{@selected_tracker_ids.join(',')})", @date_from, @date_to, @date_from, @date_to]
                           ) unless @selected_tracker_ids.empty?
    end
    @events += @project.versions.find(:all, :conditions => ["effective_date BETWEEN ? AND ?", @date_from, @date_to])
    
    @ending_events_by_days = @events.group_by {|event| event.due_date}
    @starting_events_by_days = @events.group_by {|event| event.start_date}
    
    render :layout => false if request.xhr?
  end  

  def gantt
    @trackers = Tracker.find(:all, :order => 'position')
    retrieve_selected_tracker_ids(@trackers)
    
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
    
    @events = []
    @project.issues_with_subprojects(params[:with_subprojects]) do
      @events += Issue.find(:all, 
                           :order => "start_date, due_date",
                           :include => [:tracker, :status, :assigned_to, :priority], 
                           :conditions => ["(((start_date>=? and start_date<=?) or (due_date>=? and due_date<=?) or (start_date<? and due_date>?)) and start_date is not null and due_date is not null and #{Issue.table_name}.tracker_id in (#{@selected_tracker_ids.join(',')}))", @date_from, @date_to, @date_from, @date_to, @date_from, @date_to]
                           ) unless @selected_tracker_ids.empty?
    end
    @events += @project.versions.find(:all, :conditions => ["effective_date BETWEEN ? AND ?", @date_from, @date_to])
    @events.sort! {|x,y| x.start_date <=> y.start_date }
    
    if params[:output]=='pdf'
      @options_for_rfpdf ||= {}
      @options_for_rfpdf[:file_name] = "gantt.pdf"
      render :template => "projects/gantt.rfpdf", :layout => false
    else
      render :template => "projects/gantt.rhtml"
    end
  end
  
  def search
    @question = params[:q] || ""
    @question.strip!
    @all_words = params[:all_words] || (params[:submit] ? false : true)
    @scope = params[:scope] || (params[:submit] ? [] : %w(issues changesets news documents wiki) )
    # tokens must be at least 3 character long
    @tokens = @question.split.uniq.select {|w| w.length > 2 }
    if !@tokens.empty?
      # no more than 5 tokens to search for
      @tokens.slice! 5..-1 if @tokens.size > 5
      # strings used in sql like statement
      like_tokens = @tokens.collect {|w| "%#{w}%"}
      operator = @all_words ? " AND " : " OR "
      limit = 10
      @results = []
      @results += @project.issues.find(:all, :limit => limit, :include => :author, :conditions => [ (["(LOWER(subject) like ? OR LOWER(description) like ?)"] * like_tokens.size).join(operator), * (like_tokens * 2).sort] ) if @scope.include? 'issues'
      @results += @project.news.find(:all, :limit => limit, :conditions => [ (["(LOWER(title) like ? OR LOWER(description) like ?)"] * like_tokens.size).join(operator), * (like_tokens * 2).sort], :include => :author ) if @scope.include? 'news'
      @results += @project.documents.find(:all, :limit => limit, :conditions => [ (["(LOWER(title) like ? OR LOWER(description) like ?)"] * like_tokens.size).join(operator), * (like_tokens * 2).sort] ) if @scope.include? 'documents'
      @results += @project.wiki.pages.find(:all, :limit => limit, :include => :content, :conditions => [ (["(LOWER(title) like ? OR LOWER(text) like ?)"] * like_tokens.size).join(operator), * (like_tokens * 2).sort] ) if @project.wiki && @scope.include?('wiki')
      @results += @project.repository.changesets.find(:all, :limit => limit, :conditions => [ (["(LOWER(comment) like ?)"] * like_tokens.size).join(operator), * (like_tokens).sort] ) if @project.repository && @scope.include?('changesets')
      @question = @tokens.join(" ")
    else
      @question = ""
    end
  end
  
  def feeds
    @queries = @project.queries.find :all, :conditions => ["is_public=? or user_id=?", true, (logged_in_user ? logged_in_user.id : 0)]
    @key = logged_in_user.get_or_create_rss_key.value if logged_in_user
  end
  
private
  # Find project of id params[:id]
  # if not found, redirect to project list
  # Used as a before_filter
  def find_project
    @project = Project.find(params[:id])
    @html_title = @project.name
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
  def retrieve_selected_tracker_ids(selectable_trackers)
    if ids = params[:tracker_ids]
      @selected_tracker_ids = (ids.is_a? Array) ? ids.collect { |id| id.to_i.to_s } : ids.split('/').collect { |id| id.to_i.to_s }
    else
      @selected_tracker_ids = selectable_trackers.collect {|t| t.id.to_s }
    end
  end
  
  # Retrieve query from session or build a new query
  def retrieve_query
    if params[:query_id]
      @query = @project.queries.find(params[:query_id])
      session[:query] = @query
    else
      if params[:set_filter] or !session[:query] or session[:query].project_id != @project.id
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
        session[:query] = @query
      else
        @query = session[:query]
      end
    end  
  end
end
