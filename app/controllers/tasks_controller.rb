include StoriesHelper

class TasksController < ApplicationController
  unloadable
  before_filter :find_task, :only => [:edit, :update, :show, :delete]
  before_filter :find_project, :except => [:new]  # NOTE: this is important. Otherwise, Redmine will throw a 403
  before_filter :authorize, :except => [:new]

  def create
    attribs = params.select{|k,v| k != 'id' and Task::SAFE_ATTRIBUTES.include? k }
    attribs = Hash[*attribs.flatten]
    attribs['author_id'] = User.current.id
    attribs['tracker_id'] = Task.tracker
    attribs['project_id'] = @project.id

    task = Task.new(attribs)
    if task.save!
      status = 200
    else
      status = 400
    end
    render :partial => "task", :object => task, :status => status    
  end

  def index
    @sprint = Sprint.find(params[:sprint_id])
    @story_ids = @sprint.stories.map{|s| s.id}
    @impediment_ids = @sprint.impediments.map{|i| i.id}
    @tasks = Task.find(:all, 
                       :conditions => ["parent_id in (?) AND updated_on > ?", @story_ids, params[:after]],
                       :order => "updated_on ASC")
    
    if params[:include_impediments]=='true'
      @impediments = Task.find(:all,
                               :conditions => ["id in (?) AND updated_on > ?", @impediment_ids, params[:after]],
                               :order => "updated_on ASC")
    end 

    @include_meta = true
    
    @last_updated_conditions = "parent_id in (?) " +
                               (@impediments ? "OR id in (?)" : "")
    @last_updated = Task.find(:first, 
                              :conditions => [@last_updated_conditions, @story_ids, @impediment_ids],
                              :order => "updated_on DESC")
                          
    render :action => "index", :layout => false
  end
  
  def new
    render :partial => "task", :object => Task.new
  end

  def update
    # FAT MODELS, THIN CONTROLLERS PLEASE!
    # I'd like to see this and other controller methods
    # be simplified like this:
    #
    # status = if @task.update(params)
    #            200
    #          else
    #            500
    #          end
    #
    # render :partial => "task", :object => @task, :status => status

    attribs = params.select{|k,v| Task::SAFE_ATTRIBUTES.include? k }
    attribs = Hash[*attribs.flatten]

    if IssueStatus.find(params[:status_id]).is_closed?
      attribs['remaining_hours'] = 0
    end

    result = @task.journalized_update_attributes! attribs

    if result
      @task.move_after(params[:prev])

      status = 200
    else
      status = 400
    end
    render :partial => "task", :object => @task, :status => status
  end

  private

  def find_project
    @project = if params[:project_id].nil?
                 @story.project
               else
                 Project.find(params[:project_id])
               end
  end

  def find_task
    @task = Task.find_by_id(params[:id])
  end
end
