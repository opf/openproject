
class TaskboardCardConfigurationsController < PdfExportBaseController
  before_filter :load_config

  def show
  end

  def edit
  end

  def update
    if @config.update_attributes(params[:taskboard_card_configuration])
      redirect_to pdf_export_project_pdf_export_index_path(@project.id)
    else
      render "edit"
    end
  end

  def load_config
    @config = TaskboardCardConfiguration.find(params[:id])
  end
end
