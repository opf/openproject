module OpenProject::XlsExport::Patches
  module CostReportsControllerPatch
    def self.included(base) # :nodoc:
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
        if excel_export?
          super do |format|
            yield format
            format.xls do
              report = report_to_xls
              time = DateTime.now.strftime('%d-%m-%Y-T-%H-%M-%S')
              send_data(report, type: :xls, filename: "export-#{time}.xls") if report
            end
          end
        else
          super
        end
      end

      # Build an xls file from a cost report.
      def report_to_xls
        options = { query: @query, project: @project, cost_types: @cost_types }

        sb = if @query.group_bys.empty?
               ::OpenProject::XlsExport::XlsViews::CostEntryTable.generate(options)
             elsif @query.depth_of(:column) + @query.depth_of(:row) == 1
               ::OpenProject::XlsExport::XlsViews::SimpleCostReportTable.generate(options)
             else
               ::OpenProject::XlsExport::XlsViews::CostReportTable.generate(options)
             end
        sb.xls
      end
    end
  end
end

CostReportsController.send(:include, OpenProject::XlsExport::Patches::CostReportsControllerPatch)
