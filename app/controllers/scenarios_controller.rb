class ScenariosController < ApplicationController
  unloadable
  helper :timelines

  before_filter :find_project_by_project_id
  before_filter :authorize

  accept_key_auth :index, :show

  # API actions

  def index
    @scenarios = @project.scenarios
    respond_to do |format|
      format.html { render_404 }
      format.api
    end
  end

  def show
    @scenario = @project.scenarios.find(params[:id])
    respond_to do |format|
      format.html { render_404 }
      format.api
    end
  end


  # Admin actions

  def new
    @scenario = @project.scenarios.new(:name => l('timelines.new_scenario'))
  end

  def create
    @scenario = @project.scenarios.new(permitted_params.scenario)

    if @scenario.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_settings_path
    else
      render :action => 'new'
    end
  end

  def edit
    @scenario = @project.scenarios.find(params[:id])
  end

  def update
    @scenario = @project.scenarios.find(params[:id])

    if @scenario.update_attributes(permitted_params.scenario)
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_settings_path
    else
      render :action => 'edit'
    end
  end

  def confirm_destroy
    @scenario = @project.scenarios.find(params[:id])
  end

  def destroy
    @scenario = @project.scenarios.find(params[:id])
    @scenario.destroy

    flash[:notice] = l(:notice_successful_delete)
    redirect_to project_settings_path
  end

  protected

  def project_settings_path
    url_for(:controller => 'projects', :action => 'settings', :tab => 'timelines', :id => @project)
  end
  helper_method :project_settings_path

  def default_breadcrumb
    [render_to_string(:inline => "<%= link_to(l(:label_settings), project_settings_path) %>"),
     l('timelines.scenarios')]
  end
end
