
class TaskboardCardConfigurationsController < ApplicationController
  layout 'admin'

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
    @config = TaskboardCardConfiguration.new(params[:taskboard_card_configuration])
    if @config.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index'
    else
      render "new"
    end
  end

  def update
    if @config.update_attributes(params[:taskboard_card_configuration])
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

  def load_config
    @config = TaskboardCardConfiguration.find(params[:id])
  end

  def load_configs
    @configs = TaskboardCardConfiguration.all
  end
end
