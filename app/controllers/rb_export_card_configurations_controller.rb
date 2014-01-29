
class RbExportCardConfigurationsController < RbApplicationController
  unloadable
  include OpenProject::PdfExport::ExportCard

  before_filter :load_project_and_sprint

  def index
    @configs = ExportCardConfiguration.active
  end

  def show
    config = ExportCardConfiguration.find(params[:id])

    cards_document = OpenProject::PdfExport::ExportCard::DocumentGenerator.new(config, @sprint.stories(@project))

    filename = "#{@project.to_s}-#{@sprint.to_s}-#{Time.now.strftime("%B-%d-%Y")}.pdf"
    respond_to do |format|
      format.pdf { send_data(cards_document.render,
        :disposition => 'attachment',
        :type => 'application/pdf',
        :filename => filename) }
    end
  end

  private

  def load_project_and_sprint
    @project = Project.find(params[:project_id])
    @sprint = Sprint.find(params[:sprint_id])
  end
end