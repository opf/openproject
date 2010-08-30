class RbBurndownChartsController < RbApplicationController
  unloadable

  def show
    @sprint   = Sprint.find(params[:id])
    @burndown = @sprint.burndown
    
    respond_to do |format|
      format.html { render :layout => false }
    end
  end

end
