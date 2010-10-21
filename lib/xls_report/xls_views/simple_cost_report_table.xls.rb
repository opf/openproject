require_dependency 'xls_report/xls_views'

class SimpleCostReportTable < XlsViews
  def generate
    list = query.collect {|r| r.important_fields }.flatten.uniq
    show_units = list.include? "cost_type_id"
    headers = list.collect {|field| label_for(field) }
    headers << label_for(:field_units) if show_units
    headers << label_for(:label_sum)
    spreadsheet.add_headers(headers)

    column = 0
    spreadsheet.add_format_option_to_column(headers.length - (column += 1), :number_format => number_to_currency(0.00))
    spreadsheet.add_format_option_to_column(headers.length - (column += 1), :number_format => "0.0 ?") if show_units

    query.each do |result|
      row = [show_row(result)]
      row << show_result(result, result.fields[:cost_type_id].to_i) if show_units
      row << show_result(result)
      spreadsheet.add_row(row)
    end

    footer = [''] * list.size
    footer += [''] if show_units
    spreadsheet.add_row(footer + [show_result query]) # footer
    spreadsheet
  end
end