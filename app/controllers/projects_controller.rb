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

class ProjectsController < ApplicationController
  layout 'base'
  menu_item :overview
  menu_item :activity, :only => :activity
  menu_item :roadmap, :only => :roadmap
  menu_item :files, :only => [:list_files, :add_file]
  menu_item :settings, :only => :settings
  menu_item :issues, :only => [:changelog]
  
  before_filter :find_project, :except => [ :index, :list, :add ]
  before_filter :authorize, :except => [ :index, :list, :add, :archive, :unarchive, :destroy ]
  before_filter :require_admin, :only => [ :add, :archive, :unarchive, :destroy ]
  accept_key_auth :activity, :calendar
  
  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper   
  helper :ifpdf
  include IfpdfHelper
  helper :issues
  helper IssuesHelper
  helper :queries
  include QueriesHelper
  helper :repositories
  include RepositoriesHelper
  include ProjectsHelper
  
  def index
    list
    render :action => 'list' unless request.xhr?
  end

  # Lists visible projects
  def list
    projects = Project.find :all,
                            :conditions => Project.visible_by(User.current),
                            :include => :parent
    @project_tree = projects.group_by {|p| p.parent || p}
    @project_tree.each_key {|p| @project_tree[p] -= [p]}
  end
  
  # Add a new project
  def add
    @custom_fields = IssueCustomField.find(:all, :order => "#{CustomField.table_name}.position")
    @trackers = Tracker.all
    @root_projects = Project.find(:all,
                                  :conditions => "parent_id IS NULL AND status = #{Project::STATUS_ACTIVE}",
                                  :order => 'name')
    @project = Project.new(params[:project])
    @project.enabled_module_names = Redmine::AccessControl.available_project_modules
    if request.get?
      @custom_values = ProjectCustomField.find(:all, :order => "#{CustomField.table_name}.position").collect { |x| CustomValue.new(:custom_field => x, :customized => @project) }
      @project.trackers = Tracker.all
    else
      @project.custom_fields = CustomField.find(params[:custom_field_ids]) if params[:custom_field_ids]
      @custom_values = ProjectCustomField.find(:all, :order => "#{CustomField.table_name}.position").collect { |x| CustomValue.new(:custom_field => x, :customized => @project, :value => (params[:custom_fields] ? params["custom_fields"][x.id.to_s] : nil)) }
      @project.custom_values = @custom_values
      if @project.save
        @project.enabled_module_names = params[:enabled_modules]
        flash[:notice] = l(:notice_successful_create)
        redirect_to :controller => 'admin', :action => 'projects'
	  end		
    end	
  end
	
  # Show @project
  def show
    @custom_values = @project.custom_values.find(:all, :include => :custom_field, :order => "#{CustomField.table_name}.position")
    @members_by_role = @project.members.find(:all, :include => [:user, :role], :order => 'position').group_by {|m| m.role}
    @subprojects = @project.active_children
    @news = @project.news.find(:all, :limit => 5, :include => [ :author, :project ], :order => "#{News.table_name}.created_on DESC")
    @trackers = @project.rolled_up_trackers
    Issue.visible_by(User.current) do
      @open_issues_by_tracker = Issue.count(:group => :tracker,
                                            :include => [:project, :status, :tracker],
                                            :conditions => ["(#{Project.table_name}.id=? OR #{Project.table_name}.parent_id=?) and #{IssueStatus.table_name}.is_closed=?", @project.id, @project.id, false])
      @total_issues_by_tracker = Issue.count(:group => :tracker,
                                            :include => [:project, :status, :tracker],
                                            :conditions => ["#{Project.table_name}.id=? OR #{Project.table_name}.parent_id=?", @project.id, @project.id])
    end
    TimeEntry.visible_by(User.current) do
      @total_hours = TimeEntry.sum(:hours, 
                                   :include => :project,
                                   :conditions => ["(#{Project.table_name}.id = ? OR #{Project.table_name}.parent_id = ?)", @project.id, @project.id]).to_f
    end
    @key = User.current.rss_key
  end

  def settings
    @root_projects = Project.find(:all,
                                  :conditions => ["parent_id IS NULL AND status = #{Project::STATUS_ACTIVE} AND id <> ?", @project.id],
                                  :order => 'name')
    @custom_fields = IssueCustomField.find(:all)
    @issue_category ||= IssueCategory.new
    @member ||= @project.members.new
    @trackers = Tracker.all
    @custom_values ||= ProjectCustomField.find(:all, :order => "#{CustomField.table_name}.position").collect { |x| @project.custom_values.find_by_custom_field_id(x.id) || CustomValue.new(:custom_field => x) }
    @repository ||= @project.repository
    @wiki ||= @project.wiki
  end
  
  # Edit @project
  def edit
    if request.post?
      if params[:custom_fields]
        @custom_values = ProjectCustomField.find(:all, :order => "#{CustomField.table_name}.position").collect { |x| CustomValue.new(:custom_field => x, :customized => @project, :value => params["custom_fields"][x.id.to_s]) }
        @project.custom_values = @custom_values
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
  
  def modules
    @project.enabled_module_names = params[:enabled_modules]
    redirect_to :action => 'settings', :id => @project, :tab => 'modules'
  end

  def archive
    @project.archive if request.post? && @project.active?
    redirect_to :controller => 'admin', :action => 'projects'
  end
  
  def unarchive
    @project.unarchive if request.post? && !@project.active?
    redirect_to :controller => 'admin', :action => 'projects'
  end
  
  # Delete @project
  def destroy
    @project_to_destroy = @project
    if request.post? and params[:confirm]
      @project_to_destroy.destroy
      redirect_to :controller => 'admin', :action => 'projects'
    end
    # hide project in layout
    @project = nil
  end
	
  # Add a new issue category to @project
  def add_issue_category
    @category = @project.issue_categories.build(params[:category])
    if request.post? and @category.save
  	  respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_to :action => 'settings', :tab => 'categories', :id => @project
        end
        format.js do
          # IE doesn't support the replace_html rjs method for select box options
          render(:update) {|page| page.replace "issue_category_id",
            content_tag('select', '<option></option>' + options_from_collection_for_select(@project.issue_categories, 'id', 'name', @category.id), :id => 'issue_category_id', :name => 'issue[category_id]')
          }
        end
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

  def add_file
    if request.post?
      @version = @project.versions.find_by_id(params[:version_id])
      attachments = attach_files(@version, params[:attachments])
      Mailer.deliver_attachments_added(attachments) if !attachments.empty? && Setting.notified_events.include?('file_added')
      redirect_to :controller => 'projects', :action => 'list_files', :id => @project
    end
    @versions = @project.versions.sort
  end
  
  def list_files
    @versions = @project.versions.sort.reverse
  end
  
  # Show changelog for @project
  def changelog
    @trackers = @project.trackers.find(:all, :conditions => ["is_in_chlog=?", true], :order => 'position')
    retrieve_selected_tracker_ids(@trackers)    
    @versions = @project.versions.sort
  end

  def roadmap
    @trackers = @project.trackers.find(:all, :conditions => ["is_in_roadmap=?", true])
    retrieve_selected_tracker_ids(@trackers)
    @versions = @project.versions.sort
    @versions = @versions.select {|v| !v.completed? } unless params[:completed]
  end
  
  def activity
    @days = Setting.activity_days_default.to_i
    
    if params[:from]
      begin; @date_to = params[:from].to_date; rescue; end
    end

    @date_to ||= Date.today + 1
    @date_from = @date_to - @days
    
    @event_types = %w(issues news files documents changesets wiki_pages messages)
    @event_types.delete('wiki_pages') unless @project.wiki
    @event_types.delete('changesets') unless @project.repository
    @event_types.delete('messages') unless @project.boards.any?
    # only show what the user is allowed to view
    @event_types = @event_types.select {|o| User.current.allowed_to?("view_#{o}".to_sym, @project)}
    
    @scope = @event_types.select {|t| params["show_#{t}"]}
    # default events if none is specified in parameters
    @scope = (@event_types - %w(wiki_pages messages))if @scope.empty?
    
    @events = []    
    
    if @scope.include?('issues')
      @events += @project.issues.find(:all, :include => [:author, :tracker], :conditions => ["#{Issue.table_name}.created_on>=? and #{Issue.table_name}.created_on<=?", @date_from, @date_to] )
      @events += @project.issues_status_changes(@date_from, @date_to)
    end
    
    if @scope.include?('news')
      @events += @project.news.find(:all, :conditions => ["#{News.table_name}.created_on>=? and #{News.table_name}.created_on<=?", @date_from, @date_to], :include => :author )
    end
    
    if @scope.include?('files')
      @events += Attachment.find(:all, :select => "#{Attachment.table_name}.*", :joins => "LEFT JOIN #{Version.table_name} ON #{Version.table_name}.id = #{Attachment.table_name}.container_id", :conditions => ["#{Attachment.table_name}.container_type='Version' and #{Version.table_name}.project_id=? and #{Attachment.table_name}.created_on>=? and #{Attachment.table_name}.created_on<=?", @project.id, @date_from, @date_to], :include => :author )
    end
    
    if @scope.include?('documents')
      @events += @project.documents.find(:all, :conditions => ["#{Document.table_name}.created_on>=? and #{Document.table_name}.created_on<=?", @date_from, @date_to] )
      @events += Attachment.find(:all, :select => "attachments.*", :joins => "LEFT JOIN #{Document.table_name} ON #{Document.table_name}.id = #{Attachment.table_name}.container_id", :conditions => ["#{Attachment.table_name}.container_type='Document' and #{Document.table_name}.project_id=? and #{Attachment.table_name}.created_on>=? and #{Attachment.table_name}.created_on<=?", @project.id, @date_from, @date_to], :include => :author )
    end
    
    if @scope.include?('wiki_pages')
      select = "#{WikiContent.versioned_table_name}.updated_on, #{WikiContent.versioned_table_name}.comments, " +
               "#{WikiContent.versioned_table_name}.#{WikiContent.version_column}, #{WikiPage.table_name}.title, " +
               "#{WikiContent.versioned_table_name}.page_id, #{WikiContent.versioned_table_name}.author_id, " +
               "#{WikiContent.versioned_table_name}.id"
      joins = "LEFT JOIN #{WikiPage.table_name} ON #{WikiPage.table_name}.id = #{WikiContent.versioned_table_name}.page_id " +
              "LEFT JOIN #{Wiki.table_name} ON #{Wiki.table_name}.id = #{WikiPage.table_name}.wiki_id "
      conditions = ["#{Wiki.table_name}.project_id = ? AND #{WikiContent.versioned_table_name}.updated_on BETWEEN ? AND ?",
                    @project.id, @date_from, @date_to]

      @events += WikiContent.versioned_class.find(:all, :select => select, :joins => joins, :conditions => conditions)
    end

    if @scope.include?('changesets')
      @events += Changeset.find(:all, :include => :repository, :conditions => ["#{Repository.table_name}.project_id = ? AND #{Changeset.table_name}.committed_on BETWEEN ? AND ?", @project.id, @date_from, @date_to])
    end
    
    if @scope.include?('messages')
      @events += Message.find(:all, 
                              :include => [:board, :author], 
                              :conditions => ["#{Board.table_name}.project_id=? AND #{Message.table_name}.parent_id IS NULL AND #{Message.table_name}.created_on BETWEEN ? AND ?", @project.id, @date_from, @date_to])
    end
    
    @events_by_day = @events.group_by(&:event_date)
    
    respond_to do |format|
      format.html { render :layout => false if request.xhr? }
      format.atom { render_feed(@events, :title => "#{@project.name}: #{l(:label_activity)}") }
    end
  end
  
  def calendar
    @trackers = @project.rolled_up_trackers
    retrieve_selected_tracker_ids(@trackers)
    
    if params[:year] and params[:year].to_i > 1900
      @year = params[:year].to_i
      if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
        @month = params[:month].to_i
      end    
    end
    @year ||= Date.today.year
    @month ||= Date.today.month    
    @calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)
    @with_subprojects = params[:with_subprojects].nil? ? true : (params[:with_subprojects] == '1')
    events = []
    @project.issues_with_subprojects(@with_subprojects) do
      events += Issue.find(:all, 
                           :include => [:tracker, :status, :assigned_to, :priority, :project], 
                           :conditions => ["((start_date BETWEEN ? AND ?) OR (due_date BETWEEN ? AND ?)) AND #{Issue.table_name}.tracker_id IN (#{@selected_tracker_ids.join(',')})", @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt]
                           ) unless @selected_tracker_ids.empty?
    end
    events += @project.versions.find(:all, :conditions => ["effective_date BETWEEN ? AND ?", @calendar.startdt, @calendar.enddt])
    @calendar.events = events
    
    render :layout => false if request.xhr?
  end  

  def gantt
    @trackers = @project.rolled_up_trackers
    retrieve_selected_tracker_ids(@trackers)
    
    if params[:year] and params[:year].to_i >0
      @year_from = params[:year].to_i
      if params[:month] and params[:month].to_i >=1 and params[:month].to_i <= 12
        @month_from = params[:month].to_i
      else
        @month_from = 1
      end
    else
      @month_from ||= Date.today.month
      @year_from ||= Date.today.year
    end
    
    zoom = (params[:zoom] || User.current.pref[:gantt_zoom]).to_i
    @zoom = (zoom > 0 && zoom < 5) ? zoom : 2    
    months = (params[:months] || User.current.pref[:gantt_months]).to_i
    @months = (months > 0 && months < 25) ? months : 6
    
    # Save gantt paramters as user preference (zoom and months count)
    if (User.current.logged? && (@zoom != User.current.pref[:gantt_zoom] || @months != User.current.pref[:gantt_months]))
      User.current.pref[:gantt_zoom], User.current.pref[:gantt_months] = @zoom, @months
      User.current.preference.save
    end
    
    @date_from = Date.civil(@year_from, @month_from, 1)
    @date_to = (@date_from >> @months) - 1
    @with_subprojects = params[:with_subprojects].nil? ? true : (params[:with_subprojects] == '1')
    
    @events = []
    @project.issues_with_subprojects(@with_subprojects) do
      @events += Issue.find(:all, 
                           :order => "start_date, due_date",
                           :include => [:tracker, :status, :assigned_to, :priority, :project], 
                           :conditions => ["(((start_date>=? and start_date<=?) or (due_date>=? and due_date<=?) or (start_date<? and due_date>?)) and start_date is not null and due_date is not null and #{Issue.table_name}.tracker_id in (#{@selected_tracker_ids.join(',')}))", @date_from, @date_to, @date_from, @date_to, @date_from, @date_to]
                           ) unless @selected_tracker_ids.empty?
    end
    @events += @project.versions.find(:all, :conditions => ["effective_date BETWEEN ? AND ?", @date_from, @date_to])
    @events.sort! {|x,y| x.start_date <=> y.start_date }
    
    if params[:format]=='pdf'
      @options_for_rfpdf ||= {}
      @options_for_rfpdf[:file_name] = "#{@project.identifier}-gantt.pdf"
      render :template => "projects/gantt.rfpdf", :layout => false
    elsif params[:format]=='png' && respond_to?('gantt_image')
      image = gantt_image(@events, @date_from, @months, @zoom)
      image.format = 'PNG'
      send_data(image.to_blob, :disposition => 'inline', :type => 'image/png', :filename => "#{@project.identifier}-gantt.png")
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
end
