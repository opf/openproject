
class TaskboardCardConfigurationsController < ApplicationController
  layout 'admin'

  before_filter :load_config, only: [:show, :update, :edit]
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
      redirect_to pdf_export_taskboard_card_configurations_path
    else
      render "edit"
    end
  end

  def load_config
    @config = TaskboardCardConfiguration.find(params[:id])
  end

  def load_configs
    @configs = TaskboardCardConfiguration.all
  end
end
