module ::Bim
  class LinkedIssuesController < BaseController
    include PaginationHelper

    before_action :find_project_by_project_id
    before_action :authorize

    before_action :get_issue_type
    before_action :check_file_param, only: :perform_import

    menu_item :bim

    def index
      @issues = BcfIssue
        .in_project(@project)
        .with_markup
        .includes(:comments, :work_package, viewpoints: :attachments)
        .page(page_param)
        .per_page(per_page_param)
    end

    def import; end

    def perform_import
      importer = ::OpenProject::Bim::BcfXml::Importer.new @project, current_user: current_user

      begin
        result = importer.import! params[:bcf_file].path
        flash[:notice] = I18n.t('bim.bcf.import_successful', count: result)
      rescue StandardError => e
        flash[:error] = I18n.t('bim.bcf.import_failed', error: e.message)
      end

      redirect_to action: :index
    end

    private

    def get_issue_type
      @issue_type = @project.types.find_by(name: 'Issue')
    end

    def check_file_param
      path = params[:bcf_file]&.path
      unless path && File.readable?(path)
        flash[:error] = I18n.t('bim.bcf.import_failed', error: 'File missing or not readable')
        redirect_to action: :import
      end
    end
  end
end
