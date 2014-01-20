
class PdfExportBaseController < ApplicationController
  before_filter :load_configs
  before_filter :load_project

  def load_configs
    @configs = TaskboardCardConfiguration.all
  end

  def load_project
    if params[:project_id]
      @project = Project.find(params[:project_id])
    end
  end
end