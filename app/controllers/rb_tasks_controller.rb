include RbCommonHelper

class RbTasksController < RbApplicationController
  unloadable

  def create
    @task  = Task.create_with_relationships(params, User.current.id, @project.id)
    result = @task.errors.length
    status = (result == 0 ? 200 : 400)
    @include_meta = true
    
    respond_to do |format|
      format.html { render :partial => "task", :object => @task, :status => status }
    end
  end

  def update
    @task = Task.find_by_id(params[:id])
    result = @task.update_with_relationships(params)
    status = (result ? 200 : 400)
    @include_meta = true
    
    respond_to do |format|
      format.html { render :partial => "task", :object => @task, :status => status }
    end
  end

end
