class ColorsController < ApplicationController
  unloadable
  helper :timelines

  before_filter :require_admin_unless_readonly_api_request
  accept_key_auth :index, :show

  helper :timelines
  layout 'admin'

  def index
    @colors = Color.all
    respond_to do |format|
      format.html
      format.api
    end
  end

  def show
    @color = Color.find(params[:id])
    respond_to do |format|
      format.api
    end
  end

  def new
    @color = Color.new
    respond_to do |format|
      format.html
    end
  end

  def create
    @color = Color.new(permitted_params.color)

    if @color.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to colors_path
    else
      flash.now[:error] = l('timelines.color_could_not_be_saved')
      render :action => "new"
    end
  end

  def edit
    @color = Color.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def update
    @color = Color.find(params[:id])

    if @color.update_attributes(permitted_params.color)
      flash[:notice] = l(:notice_successful_update)
      redirect_to colors_path
    else
      flash.now[:error] = l('timelines.color_could_not_be_saved')
      render :action => 'edit'
    end
  end

  def move
    @color = Color.find(params[:id])

    if @color.update_attributes(permitted_params.color_move)
      flash[:notice] = l(:notice_successful_update)
    else
      render :action => 'edit'
    end
    redirect_to colors_path
  end

  def confirm_destroy
    @color = Color.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def destroy
    @color = Color.find(params[:id])
    @color.destroy

    flash[:notice] = l(:notice_successful_delete)
    redirect_to colors_path
  end

  protected

  def default_breadcrumb
    l('timelines.admin_menu.colors')
  end

  def require_admin_unless_readonly_api_request
    require_admin unless %w[index show].include? params[:action] and
                         api_request?
  end
end
