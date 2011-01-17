# Only apply this patch if the redmine_costs plugin is available
if require_dependency 'cost_reports_controller'
  require_dependency 'xls_report/spreadsheet_builder'
  require_dependency 'xls_report/xls_views'

  module XlsReport
    module CostReportsControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method_chain :ensure_project_scope?, :excel_export
        end
      end

      module InstanceMethods

        def excel_export?
          params["action"] == "index" && params["format"] == "xls"
        end

        def ensure_project_scope_with_excel_export?
          !excel_export? && ensure_project_scope_without_excel_export?
        end

        # If the index action is called, hook the xls format into the cost report
        def respond_to
          if excel_export?
            super do |format|
              yield format
              format.xls do
                report = report_to_xls
                time = DateTime.now.strftime('%d-%m-%Y-T-%H-%M-%S')
                send_data(report, :type => :xls, :filename => "export-#{time}.xls") if report
              end
            end
          else
            super
          end
        end

        # Build an xls file from a cost report.
        def report_to_xls
          find_optional_project
          generate_query
          set_active_cost_types
          options = { :query => @query, :project => @project, :cost_types => @cost_types }

          if @query.group_bys.empty?
            sb = CostEntryTable.generate(options)
          else
            if @query.depth_of(:column) == 0 || @query.depth_of(:row) == 0
              @query.depth_of(:column) == 0 ? @query.column(:singleton_value) : @query.row(:singleton_value)
            end
            sb = CostReportTable.generate(options)
          end
          sb.xls
        end
      end
    end
  end

  CostReportsController.send(:include, XlsReport::CostReportsControllerPatch)
end
