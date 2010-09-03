class RbUpdatedItemsController < RbApplicationController
  unloadable
  
  # Returns all models that have changed since params[:since]
  # params[:only] limits the types of models that the method
  # should return
  def show
    only  = (params[:only] ? params[:only].split(/, ?/).map{|v| v.to_sym} : [:sprints, :stories, :tasks, :impediments])
    @items = HashWithIndifferentAccess.new
    
    if only.include? :stories
      @items[:stories] = Story.find_all_updated_since(params[:since], @project.id)
    end
    
    if only.include? :tasks
      @items[:tasks] = Task.find_all_updated_since(params[:since], @project.id)
    end

    if only.include? :impediments
      @items[:impediments] = Task.find_all_updated_since(params[:since], @project.id, true)
    end
    
    respond_to do |format|
      format.html { render :layout => false }
    end
  end
end