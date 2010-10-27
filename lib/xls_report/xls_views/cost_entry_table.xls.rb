require_dependency 'xls_report/xls_views'

class CostEntryTable < XlsViews
  def generate
    spreadsheet = SpreadsheetBuilder.new(cost_type_label(@unit_id))
    spreadsheet.add_title("#{@project.name + " >> " if @project}#{l(:cost_reports_title)} (#{format_date(Date.today)})")

    list = [:spent_on, :user_id, :activity_id, :issue_id, :comments, :project_id]
    headers = list.collect {|field| label_for(field) }
    headers << (cost_type.try(:unit_plural) || l(:units))
    headers << l(:field_costs)
    spreadsheet.add_headers(headers)

    spreadsheet.add_format_option_to_column(headers.length - 1, :number_format => number_to_currency(0.00))
    spreadsheet.add_format_option_to_column(headers.length - 2, :number_format => "0.0")

    query.each_direct_result do |result|
      row = list.collect {|field| show_field field, result.fields[field.to_s] }
      row << show_result(result, result.fields['cost_type_id'].to_i) # units
      row << show_result(result, 0) # currency
      spreadsheet.add_row(row)
    end

    footer = [''] * list.size
    if show_result(query, 0) != show_result(query)
      footer += [show_result(query), show_result(query, 0)]
    else
      footer += ['', show_result(query)]
    end
    spreadsheet.add_row(footer) # footer

    spreadsheet
  end
end
