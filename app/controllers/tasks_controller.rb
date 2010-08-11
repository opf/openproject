include StoriesHelper

class TasksController < ApplicationController
  unloadable
  before_filter :find_task, :only => [:edit, :update, :show, :delete]
  before_filter :find_project, :except => [:new]  # NOTE: this is important. Otherwise, Redmine will throw a 403
  before_filter :authorize, :except => [:new]

  def create
    # FAT MODELS, SKINNY CONTROLLERS PLEASE!
    # http://weblog.jamisbuck.org/2006/10/18/skinny-controller-fat-model
    @task = Task.create_with_relationships(params, User.current.id, @project.id, params[:is_impediment])
    status = if @task.errors.length==0
               200
             else
               400
             end

    @include_meta = true
    render :partial => (params[:is_impediment] ? "impediment" : "task"), :object => @task, :status => status
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
    status = if @task.update_with_relationships(params, params[:is_impediment])
               200
             else
               400
             end

    @include_meta = true
    render :partial => (params[:is_impediment] ? "impediment" : "task"), :object => @task, :status => status
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
