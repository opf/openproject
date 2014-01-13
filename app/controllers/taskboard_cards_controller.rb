
class TaskboardCardsController < PdfExportBaseController
  include OpenProject::PdfExport::TaskboardCard

  def index
    work_packages = @project.work_packages
    document = OpenProject::PdfExport::TaskboardCard::DocumentGenerator.new(@default_config, work_packages)

    respond_to do |format|
      format.pdf { send_data(document.render, :disposition => 'attachment', :type => 'application/pdf') }
    end
  end
end