
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
      redirect_to pdf_export_taskboard_card_configurations_path
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
    # TODO RS: Should not be able to delete the default config. Get that onto the model preferably.
    if @config.destroy
      flash[:notice] = l(:notice_successful_delete)
    end
      flash[:notice] = l(:error_can_not_delete_taskboard_card_configuration)
    else
    redirect_to :action => 'index'
  end

  def load_config
    @config = TaskboardCardConfiguration.find(params[:id])
  end

  def load_configs
    @configs = TaskboardCardConfiguration.all
  end
end
