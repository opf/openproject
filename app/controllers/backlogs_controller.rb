include StoriesHelper
include BacklogMenuHelper

require 'icalendar'

class BacklogsController < ApplicationController
  unloadable

  include Cards

  before_filter :find_sprint, :only => [:show]
  before_filter :find_project, :authorize

  def index
    @settings = Setting.plugin_redmine_backlogs
    @product_backlog_stories = Story.product_backlog(@project)
    @sprints = Sprint.open_sprints(@project)
    @velocity = @project.scrum_statistics
    
    if @settings[:story_trackers].nil? || @settings[:task_tracker].nil?
      render :action => "noconfig", :layout => "backlogs"
    else
      render :action => "index", :layout => "backlogs"
    end
  end
  
  def show
    @statuses = Tracker.find_by_id(Task.tracker).issue_statuses
  end

  def burndown
    sprint = Sprint.find_by_id(params[:sprint_id])
    @burndown = sprint.burndown
    render :action => "burndown", :layout => "backlogs"
  end
  
  def jsvariables
    render :action => "jsvariables.js", :content_type => 'text/javascript', :layout => false
  end

  def reorder
    dropped = params[:dropped]

    pred = nil
    found = false
    if !params[:story].nil?
        params[:story].each { |id|
            if id == dropped
                found = true
                break
            end
            pred = id
        }
    end

    if found
        story = Story.find(dropped)

        if params[:moveto]
            if params[:moveto] == 'product_backlog'
                story.journalized_update_attribute(:fixed_version_id, nil)
            else
                sprint = params[:moveto]
                sprint = Sprint.first(:conditions => { :project_id => @project.id, :id => sprint})
                story.journalized_update_attribute(:fixed_version_id, sprint.id)
            end
        end

        if pred.nil?
            story.move_to_top
        else
            pred = Story.find(pred)
            story.insert_at(pred.position + 1)
        end
    end

    render :nothing => true, :status => 200
  end

  def rename
    type, name, id = (params[:id].split('-'))
    value = params[:value]

    if type == 'sprint'
        sprint = Sprint.first(:conditions => { :project_id => @project.id, :id => id})
        sprint.update_attribute(:name, value)
    elsif type == 'story'
        story = Story.first(:conditions => { :project_id => @project.id, :id => id})
        story.journalized_update_attribute(:subject, value)
    else
        render :nothing => true, :status => 500
    end

    render :text => value, :status => 200
  end

  def sprint_date
    date = params[:date]
    sprint = params[:sprint]
    type = params[:type]

    sprint = Sprint.first(:conditions => { :project_id => @project.id, :id => sprint})

    if type == 'start'
        sprint.update_attribute(:start_date, date)
    elsif type == 'end'
        sprint.update_attribute(:effective_date, date)
    else
        render :nothing => true, :status => 500
    end

    render :text => date, :status => 200
  end

  def story_points
    points, sprint, story, id = params[:id].split('-')
    story = Story.first(:conditions => { :project_id => @project.id, :id => id})

    begin
        story.set_points(params[:value])
    rescue
        # ignore non-integer values
    end

    render :text => story.points_display, :status => 200
  end

  def select_issues
    @query = Query.new(:name => "_")
    @query.project = @project

    if params[:sprint_id]
        @query.add_filter("status_id", '*', ['']) # All statuses
        @query.add_filter("fixed_version_id", '=', [params[:sprint_id]])
        @query.add_filter("backlogs_issue_type", '=', ['any'])
        @query.sort_criteria = [['parent_id', 'desc']]
    else
        @query.add_filter("status_id", 'o', ['']) # only open
        @query.add_filter("fixed_version_id", '!*', ['']) # only unassigned
        @query.add_filter("backlogs_issue_type", '=', ['story'])
        @query.sort_criteria = [['position', 'asc']]
    end

    session[:query] = {:project_id => @query.project_id, :filters => @query.filters}

    redirect_to :controller => 'issues', :action => 'index', :project_id => @project.id
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
    render :text => result
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
      cal.todo do
        summary     summary_text
        description description_text
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
