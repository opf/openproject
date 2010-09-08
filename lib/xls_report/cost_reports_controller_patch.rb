# Only apply this patch if the redmine_costs plugin is available
if require_dependency 'cost_reports_controller'
  require_dependency 'xls_report/spreadsheet_builder'

  module XlsReport
    module CostReportsControllerPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
        end
      end

      module InstanceMethods
        include Redmine::I18n
        include ActionView::Helpers::NumberHelper

        # If the index action is called, hook the xls format into the cost report
        def respond_to
          if (params["action"] == "index" && params["format"] == "xls")
            super do |format|
              yield format
              format.xls do
                send_data(report_to_xls, :type => :xls, :filename => 'export.xls')
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
          set_cost_type

          debugger
          sb = SpreadsheetBuilder.new
          sb.add_title("#{@project.name} >> #{l(:cost_reports_title)} (#{format_date(Date.today)})")

          if @query.group_bys.empty?
            sb = xls_cost_entry_table(sb, @query, @cost_type)
          elsif @query.depth_of(:column) + @query.depth_of(:row) == 1
            sb = xls_simple_cost_report_table(sb, @query, @cost_type)
          else
            # @table_partial = "cost_report_table"
          end
          sb.xls
        end

        def xls_cost_entry_table(sb, query, cost_type)
          list = [:project_id, :issue_id, :spent_on, :user_id, :activity_id]
          headers = list.collect {|field| label_for(field) }
          headers << l(:field_costs)
          headers << cost_type.try(:unit_plural) || l(:units)
          sb.add_headers(headers)

          sb.add_format_option_to_column(headers.length - 2, :number_format => number_to_currency(0.00))
          sb.add_format_option_to_column(headers.length - 1, :number_format => "0.0")

          query.each_direct_result do |result|
            row = list.collect {|field| show_field field, result.fields[field.to_s] }
            row << show_result(result) # currency
            row << show_result(result, result.fields['cost_type_id'].to_i) # units
            sb.add_row(row)
          end
          sb.add_row([show_result query]) # footer
          sb
        end

        def xls_simple_cost_report_table(sb, query, cost_type)
          list = query.collect {|r| r.important_fields }.flatten.uniq
          show_units = list.include? "cost_type_id"
          headers = list.collect {|field| label_for(field) }
          headers << label_for(:label_count)
          headers << label_for(:field_units) if show_units
          headers << label_for(:label_sum)
          sb.add_headers(headers)

          column = 0
          sb.add_format_option_to_column(headers.length - (column += 1), :number_format => number_to_currency(0.00))
          sb.add_format_option_to_column(headers.length - (column += 1), :number_format => "0.0 ?") if show_units
          sb.add_format_option_to_column(headers.length - (column += 1), :number_format => "0.0")

          query.each do |result|
            row = [show_row(result), result.count]
            row << show_result(result, result.fields[:cost_type_id].to_i) if show_units
            row << show_result(result)
            sb.add_row(row)
          end
          sb.add_row([show_result query]) # footer
          sb
        end

      end
    end
  end

  CostReportsController.send(:include, XlsReport::CostReportsControllerPatch)
end
