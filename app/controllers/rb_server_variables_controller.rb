class RbServerVariablesController < RbApplicationController
  unloadable

  def show
    @sprint = params[:sprint_id] ? Sprint.find(params[:sprint_id]) : nil
    respond_to do |format|
      format.js { render :layout => false }
    end
  end
end