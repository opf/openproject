class RbBurndownChartsController < RbApplicationController
  unloadable

  def show
    @burndown = @sprint.burndown(@project)

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

end
