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
              time = Time.now.strftime('%d-%m-%Y-T-%H-%M-%S')
              send_data(report, type: :xls, filename: "export-#{time}.xls") if report
            end
          end
        else
          super
        end
      end

      # Build an xls file from a cost report.
      # We only support extracting a simple xls table, so grouping is ignored.
      def report_to_xls
        export_query = build_query(filter_params)

        options = { query: export_query, project: @project, cost_types: @cost_types }

        ::OpenProject::XlsExport::XlsViews::CostEntryTable.generate(options).xls
      end
    end
  end
end

CostReportsController.send(:include, OpenProject::XlsExport::Patches::CostReportsControllerPatch)
