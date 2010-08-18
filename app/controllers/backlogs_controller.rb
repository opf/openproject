include StoriesHelper
include TasksHelper
include BacklogMenuHelper

require 'icalendar'

class BacklogsController < ApplicationController
  unloadable

  include Cards

  accept_key_auth :calendar
  before_filter :find_sprint, :only => [:show]
  before_filter :find_project, :authorize

  def index
    @settings = Setting.plugin_redmine_backlogs
    @product_backlog_stories = Story.product_backlog(@project)
    @sprints = Sprint.open_sprints(@project)
    @velocity = @project.scrum_statistics
    @last_updated = Story.find(:first, 
                          :conditions => ["project_id=? AND tracker_id in (?)", @project, Story.trackers],
                          :order => "updated_on DESC")

    if @settings[:story_trackers].nil? || @settings[:task_tracker].nil?
      render :action => "noconfig", :layout => "backlogs"
    else
      render :action => "index", :layout => "backlogs"
    end
  end
  
  def show
    @statuses = Tracker.find_by_id(Task.tracker).issue_statuses
    @story_ids = @sprint.stories.map{|s| s.id}
    @last_updated = Task.find(:first, 
                          :conditions => ["parent_id in (?)", @story_ids],
                          :order => "updated_on DESC")
  end

  def burndown
    sprint = Sprint.find_by_id(params[:sprint_id])
    @burndown = sprint.burndown
    render :action => "burndown", :layout => "backlogs"
  end
  
  def jsvariables
    @sprint = params[:sprint_id] ? Sprint.find(params[:sprint_id]) : nil
    render :action => "jsvariables.js", :content_type => 'text/javascript', :layout => false
  end

  def select_issues
    @query = Query.new(:name => "_")
    @query.project = @project

    if params[:sprint_id]
        @query.add_filter("status_id", '*', ['']) # All statuses
        @query.add_filter("fixed_version_id", '=', [params[:sprint_id]])
        @query.add_filter("backlogs_issue_type", '=', ['any'])
    else
        @query.add_filter("status_id", 'o', ['']) # only open
        @query.add_filter("fixed_version_id", '!*', ['']) # only unassigned
        @query.add_filter("backlogs_issue_type", '=', ['story'])
    end

    column_names = @query.columns.collect{|col| col.name}
    column_names = column_names + ['position'] unless column_names.include?('position')

    session[:query] = {:project_id => @query.project_id, :filters => @query.filters, :column_names => column_names}
    redirect_to :controller => 'issues', :action => 'index', :project_id => @project.id, :sort => 'position'
  end

  def select_product_backlog
    @query = Query.new(:name => "_")
    @query.project = @project

    @query.add_filter("status_id", 'o', ['']) # only open
    @query.add_filter("fixed_version_id", '!*', ['']) # only unassigned
    @query.add_filter("backlogs_issue_type", '=', ['story'])

    session[:query] = {:project_id => @query.project_id, :filters => @query.filters}

    redirect_to :controller => 'issues', :action => 'index', :project_id => @project.id
  end
  
  def update
    sprint = Sprint.find(params[:id])
    attribs = params.select{|k,v| k != 'id' and Sprint.column_names.include? k }
    attribs = Hash[*attribs.flatten]
    result = sprint.update_attributes attribs
    if result
      render :text => 'successfully updated sprint', :status => 200
    else
      render :partial => 'shared/validation_errors', :object => sprint.errors, :status => 400
    end
  end

  def wiki_page
    sprint = Sprint.first(:conditions => { :project_id => @project.id, :id => params[:sprint_id]})
    redirect_to :controller => 'wiki', :action => 'index', :id => @project.id, :page => sprint.wiki_page
  end

  def wiki_page_edit
    sprint = Sprint.first(:conditions => { :project_id => @project.id, :id => params[:sprint_id]})
    redirect_to :controller => 'wiki', :action => 'edit', :id => @project.id, :page => sprint.wiki_page
  end

  def product_backlog_cards
    cards = TaskboardCards.new(current_language)

    Story.product_backlog(@project).each {|story|
        cards.add(story, false)
    }

    send_data(cards.pdf.render, :filename => 'cards.pdf', :disposition => 'attachment', :type => 'application/pdf')
  end

  def taskboard_cards
    sprint = Sprint.first(:conditions => { :project_id => @project.id, :id => params[:sprint_id]})
    cards = TaskboardCards.new(current_language)

    sprint.stories.each {|story|
        cards.add(story)
    }

    send_data(cards.pdf.render, :filename => 'cards.pdf', :disposition => 'attachment', :type => 'application/pdf')
  end

  def calendar
    cal = Icalendar::Calendar.new

    # current + future sprints
    Sprint.find(:all, :conditions => ["not sprint_start_date is null and not effective_date is null and project_id = ? and effective_date >= ?", @project.id, Date.today]).each {|sprint|
      summary_text = l(:event_sprint_summary, { :project => @project.name, :summary => sprint.name } )
      description_text = l(:event_sprint_description, {
                            :summary => sprint.name,
                            :description => sprint.description,
                            :url => url_for({
                              :controller => 'backlogs',
                              :only_path => false,
                              :action => 'select_issues',
                              :project_id => @project.id,
                              :sprint_id => sprint.id
                              })
                            })
      cal.event do
        dtstart     sprint.sprint_start_date
        dtend       sprint.effective_date
        summary     summary_text
        description description_text
        klass       'PRIVATE'
        transp      'TRANSPARENT'
      end
    }

    open_issues = "
        #{IssueStatus.table_name}.is_closed = ?
        and tracker_id in (?)
        and fixed_version_id in (
          select id
          from versions
          where project_id = ?
            and status = 'open'
            and not sprint_start_date is null
            and effective_date >= ?
        )
    "
    open_issues_and_impediments = "
      (assigned_to_id is null or assigned_to_id = ?)
      and
      (
        (#{open_issues})
        or
        ( #{IssueStatus.table_name}.is_closed = ?
          and #{Issue.table_name}.id in (
            select issue_from_id
            from issue_relations
            join issues on issues.id = issue_to_id and relation_type = 'blocks'
            where #{open_issues})
        )
      )
    "

    conditions = [open_issues_and_impediments]
    # me or none
    conditions << User.current.id

    # open stories/tasks
    conditions << false
    conditions << Story.trackers + [Task.tracker]
    conditions << @project.id
    conditions << Date.today

    # open impediments...
    conditions << false

    # ... for open stories/tasks
    conditions << false
    conditions << Story.trackers + [Task.tracker]
    conditions << @project.id
    conditions << Date.today

    issues = Issue.find(:all, :include => :status, :conditions => conditions).each {|issue|
      summary_text = l(:todo_issue_summary, { :type => issue.tracker.name, :summary => issue.subject } )
      description_text = l(:todo_issue_description, {
                            :summary => issue.subject,
                            :description => issue.description,
                            :url => url_for({
                              :controller => 'issues',
                              :only_path => false,
                              :action => 'show',
                              :id => issue.id
                              })
                            })
      # I know this should be "cal.todo do", but outlook in it's
      # infinite stupidity doesn't support VTODO
      cal.event do
        summary     summary_text
        description description_text
        dtstart     Date.today
        dtend       (Date.today + 1)
        klass       'PRIVATE'
        transp      'TRANSPARENT'
      end
    }

    send_data(cal.to_ical, :filename => "#{@project.identifier}.ics", :disposition => 'attachment', :type => 'text/calendar')
  end

  private

  def find_project
    @project = (params[:project_id] ? Project.find(params[:project_id]) : @sprint.project)
  end
  
  def find_sprint
    @sprint = Sprint.find(params[:id])
  end
end
