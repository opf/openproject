class TasksController < ApplicationController
  unloadable
  before_filter :find_task, :only => [:edit, :update, :show, :delete]
  before_filter :find_project  # NOTE: this is important. Otherwise, Redmine will throw a 403
  before_filter :authorize

  def index
    render :text => "We don't do no indexin' round this part o' town."
  end

  def update
    attribs = params.select{|k,v| k != 'id' and k != 'project_id' and Task.column_names.include? k }
    attribs = Hash[*attribs.flatten]
    result = @task.journalized_update_attributes! attribs
    if result
      text = "Task updated successfully."
      status = 200
    else
      text = "ERROR: Task could not be saved."
      status = 500
    end
    render :text => text, :status => status
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
