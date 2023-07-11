module OpenProject::XlsExport::Patches
  module CostReportsControllerPatch
    def self.included(base)
      # :nodoc:
      base.prepend InstanceMethods
    end

    module InstanceMethods
      def excel_export?
        (params["action"] == "index" or params[:action] == "all") && params["format"] == "xls"
      end

      def ensure_project_scope?
        !excel_export? && super
      end

      # If the index action is called, hook the xls format into the cost report
      def respond_to
        return super unless excel_export?

        super do |format|
          yield format
          format.xls do
            job_id = XlsExport::CostReports::ScheduleExportService
              .new(user: current_user)
              .call(filter_params:, project: @project, cost_types: @cost_types)
              .result

            redirect_to job_status_path(job_id)
          end
        end
      end
    end
  end
end

CostReportsController.include OpenProject::XlsExport::Patches::CostReportsControllerPatch
