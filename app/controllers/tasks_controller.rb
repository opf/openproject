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
      c = task.parent.children
      task.move_to_left_of c[0] if c[0].id != task.id
      render :partial => "task", :object => task
    else
      text = "ERROR"
      status = 500
      render :text => text, :status => status
    end
  end

  def index
    render :text => "We don't do no indexin' round this part o' town."
  end
  
  def new
    render :partial => "task", :object => Task.new
  end

  def update
    attribs = params.select{|k,v| Task::SAFE_ATTRIBUTES.include? k }
    attribs = Hash[*attribs.flatten]

    if IssueStatus.find(params[:status_id]).is_closed?
      attribs['remaining_hours'] = 0
    end

    result = @task.journalized_update_attributes! attribs
    if result
      render :partial => "task", :object => @task
    else
      text = "ERROR: Task could not be saved."
      status = 500
      render :text => text, :status => status
    end
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
