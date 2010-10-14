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

        # Overwrite a few mappings.
        def field_representation_map(key, value)
          case key.to_sym
          when :units                     then value.to_i
          when :spent_on                  then value.to_date
          when :activity_id               then mapped value, Enumeration, l(:caption_material_costs)
          when :project_id                then (l(:label_none) if value.to_i == 0) or Project.find(value.to_i).name
          when :user_id, :assigned_to_id  then (l(:label_none) if value.to_i == 0) or User.find(value.to_i).name
          when :issue_id
            return l(:label_none) if value.to_i == 0
            issue = Issue.find(value.to_i)
            "#{issue.project.name + " - " if @project}#{issue.tracker} ##{issue.id}: #{issue.subject}"
          else super(key, value)
          end
        end

        def show_result(row, unit_id = @unit_id)
          case unit_id
          when 0 then row.real_costs ? row.real_costs : '-'
          else row.units
          end
        end

        # Build an xls file from a cost report.
        def report_to_xls
          find_optional_project
          generate_query
          set_cost_types

          sb = SpreadsheetBuilder.new
          sb.add_title("#{@project.name + " >> " if @project}#{l(:cost_reports_title)} (#{format_date(Date.today)})")

          if @query.group_bys.empty?
            sb = xls_cost_entry_table(sb, @query, @cost_type)
          elsif @query.depth_of(:column) + @query.depth_of(:row) == 1
            sb = xls_simple_cost_report_table(sb, @query, @cost_type)
          else
            sb = xls_cost_report_table(sb, @query, @cost_type)
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

        def xls_cost_report_table(sb, query, cost_type)
          walker = query.walker
          walker.for_final_row do |final_row, cells|
            row = [show_row final_row]
            row += cells
            row << show_result(final_row)
          end

          walker.for_row do |row, subrows|
            unless row.fields.empty?
              # Here we get the border setting, vertically. The rowspan #{subrows.size} need be
              # converted to a proper Excel bordering
              subrows = subrows.inject([]) do |array, subrow|
                if subrow.flatten == subrow
                  array << subrow
                else
                  array += subrow.collect(&:flatten)
                end
              end
              subrows.each_with_index do |subrow, idx|
                if idx == 0
                  subrow.insert(0, show_row(row))
                  subrow << show_result(row)
                else
                  subrow.unshift("")
                  subrow << ""
                end
              end
            end
            subrows
          end

          walker.for_empty_cell { "" }

          walker.for_cell do |result|
            show_result result
          end

          headers = []
          header  = []
          walker.headers do |list, first, first_in_col, last_in_col|
            if first_in_col # Open a new header row
              header = [""] * query.depth_of(:row) # TODO: needs borders: rowspan=query.depth_of(:column)
            end

            list.each do |column|
              header << show_row(column)
              header += [""] * (column.final_number(:column) - 1)
            end

            if last_in_col # Finish this header row
              header += [""] * query.depth_of(:row) # TODO: needs borders: rowspan=query.depth_of(:column)
              headers << header
            end
          end

          footers = []
          footer  = []
          walker.reverse_headers do |list, first, first_in_col, last_in_col|
            if first_in_col # Open a new footer row
              footer = [""] * query.depth_of(:row) # TODO: needs borders: rowspan=query.depth_of(:column)
            end

            list.each do |column|
              footer << show_result(column)
              footer += [""] * (column.final_number(:column) - 1)
            end

            if last_in_col # Finish this footer row
              if first
                footer << show_result(query)
                footer += [""] * (query.depth_of(:row) - 1) # TODO: add rowspan=query.depth_of(:column)
              else
                footer += [""] * query.depth_of(:row) # TODO: add rowspan=query.depth_of(:column)
              end
              footers << footer
            end
          end

          row_length = headers.first.length
          rows = []
          walker.body do |line|
            # Question: what is line
            if line.respond_to? :to_ary
              # We're dealing with a list of lines
              rows += line.flatten
            else
              rows << line
            end
          end

          label = "#{l(:caption_cost_type)}: "
          label += (case @unit_id
          when -1 then l(:field_hours)
          when 0  then "EUR"
          else @cost_type.unit_plural
          end)

          sb.add_headers([label])
          headers.each {|head| sb.add_headers(head, sb.current_row) }
          rows.in_groups_of(row_length).each {|body| sb.add_row(body) }
          footers.each {|foot| sb.add_headers(foot, sb.current_row) }
          sb
        end
      end
    end
  end

  CostReportsController.send(:include, XlsReport::CostReportsControllerPatch)
end
