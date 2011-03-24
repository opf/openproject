class RbBurndownChartsController < RbApplicationController
  unloadable

  def show
    @burndown = @sprint.burndown

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

end
