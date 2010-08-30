class RbChangesController < RbApplicationController
  unloadable
  
  def show
    # Gather all that has changed in the project (params[:id]) since params[:last_update]
    
    respond_to do |format|
      format.html
    end
  end
end