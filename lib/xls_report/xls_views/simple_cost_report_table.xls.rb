require_dependency 'xls_report/xls_views'

class SimpleCostReportTable < XlsViews
  def generate
    spreadsheet = SpreadsheetBuilder.new(l(:label_money))
    default_query = @query.serialize

    available_cost_type_tabs(options[:cost_types]).each_with_index do |ary, idx|
      @query = CostQuery.deserialize(default_query)
      @cost_type = nil
      @unit_id = ary.first
      name = ary.last

      if @unit_id != 0
        @query.filter :cost_type_id, :operator => '=', :value => @unit_id.to_s
        @cost_type = CostType.find(unit_id) if unit_id > 0
      end

      spreadsheet.worksheet(idx, name)
      build_spreadsheet(spreadsheet)
    end
    spreadsheet
  end

  def build_spreadsheet(spreadsheet)
    spreadsheet.add_title("#{@project.name + " >> " if @project}#{l(:cost_reports_title)} (#{format_date(Date.today)})")

    list = query.collect {|r| r.important_fields }.flatten.uniq
    show_units = list.include? "cost_type_id"
    headers = list.collect {|field| label_for(field) }
    headers << label_for(:field_units) << "" if show_units
    headers << label_for(:label_sum) << ""
    spreadsheet.add_headers(headers)

    column = 0
    spreadsheet.add_format_option_to_column(headers.length - (column += 1), :number_format => number_to_currency(0.00))
    spreadsheet.add_format_option_to_column(headers.length - (column += 1), :number_format => "0.0 ?") if show_units

    query.each do |result|
      current_cost_type_id = result.fields[:cost_type_id].to_i
      row = [show_row(result)]
      row << show_result(result, current_cost_type_id) if show_units
      row << cost_type_unit_label(current_cost_type_id, @cost_type) if show_units
      row << show_result(result)
      row << cost_type_unit_label(@unit_id, @cost_type)
      spreadsheet.add_row(row)
    end

    footer = [''] * list.size
    footer += ['', ''] if show_units
    spreadsheet.add_row(footer + [show_result(query), cost_type_unit_label(@unit_id, @cost_type)]) # footer
    spreadsheet
  end
end
