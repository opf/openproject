
class PdfExportBaseController < ApplicationController
  include OpenProject::PdfExport::Exceptions

  before_filter :load_configs
  before_filter :load_project

  rescue_from BadlyFormedTaskboardCardConfigurationError, with: :show_errors

  def load_configs
    @configs = TaskboardCardConfiguration.all
  end

  def load_project
    if params[:project_id]
      @project = Project.find(params[:project_id])
    end
  end

  def show_errors
    redirect_to pdf_export_project_pdf_export_index_path(@project.id)
  end
end