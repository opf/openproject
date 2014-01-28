
class TaskboardCardConfigurationsController < ApplicationController
  layout 'admin'

  before_filter :require_admin
  before_filter :load_config, only: [:show, :update, :edit, :destroy]
  before_filter :load_configs, only: [:index]

  def index
  end

  def show
  end

  def edit
  end

  def new
    @config = TaskboardCardConfiguration.new
  end

  def create
    @config = TaskboardCardConfiguration.new(taskboard_card_configurations_params)
    if @config.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index'
    else
      render "new"
    end
  end

  def update
    if cannot_update_default
      flash[:error] = l(:error_can_not_change_name_of_default_configuration)
      render "edit"
    elsif @config.update_attributes(taskboard_card_configurations_params)
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    else
      render "edit"
    end
  end

  def destroy
    if !@config.is_default? && @config.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:notice] = l(:error_can_not_delete_taskboard_card_configuration)
    end
    redirect_to :action => 'index'
  end

  private

  def cannot_update_default
    @config.is_default? && taskboard_card_configurations_params[:name].downcase != "default"
  end

  def taskboard_card_configurations_params
    params.require(:taskboard_card_configuration).permit(:name, :rows, :per_page, :page_size, :orientation)
  end

  def load_config
    @config = TaskboardCardConfiguration.find(params[:id])
  end

  def load_configs
    @configs = TaskboardCardConfiguration.all
  end
end
