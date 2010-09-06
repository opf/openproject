class RbServerVariablesController < RbApplicationController
  unloadable

  def show
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
end
