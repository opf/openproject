
class PdfExportBaseController < ApplicationController
  before_filter :load_default_config
  before_filter :load_project

  def load_default_config
    @default_config = TaskboardCardConfiguration.first
  end

  def load_project
    if params[:project_id]
      @project = Project.find(params[:project_id])
    end
  end
end