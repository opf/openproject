
class TaskboardCardsController < PdfExportBaseController
  include OpenProject::PdfExport::TaskboardCard

  def show
    config = TaskboardCardConfiguration.find(params[:id])
    if config.nil?
      config = TaskboardCardConfiguration.where({:identifier => "default"}).first
    end
    work_packages = @project.work_packages
    document = OpenProject::PdfExport::TaskboardCard::DocumentGenerator.new(config, work_packages)

    respond_to do |format|
      format.pdf { send_data(document.render, :disposition => 'attachment', :type => 'application/pdf') }
    end
  end
end