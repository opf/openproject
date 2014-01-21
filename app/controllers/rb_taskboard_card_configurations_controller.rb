
class RbTaskboardCardConfigurationsController < RbApplicationController
  unloadable
  include OpenProject::PdfExport::TaskboardCard
  before_filter :load_project_and_sprint

  def index
    @configs = TaskboardCardConfiguration.all
  end

  def show
    config = TaskboardCardConfiguration.find(params[:id])

    cards_document = OpenProject::PdfExport::TaskboardCard::DocumentGenerator.new(config, @sprint.stories(@project))

    respond_to do |format|
      format.pdf { send_data(cards_document.render, :disposition => 'attachment', :type => 'application/pdf') }
    end
  end

  def load_project_and_sprint
    @project = Project.find(params[:project_id])
    @sprint = Sprint.find(params[:sprint_id])
  end
end