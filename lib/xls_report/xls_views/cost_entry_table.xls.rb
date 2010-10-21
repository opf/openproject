require_dependency 'xls_report/xls_views'

class CostEntryTable < XlsViews
  def generate(sb, query, cost_type, unit_id)
    list = [:spent_on, :user_id, :activity_id, :issue_id, :comments, :project_id]
    headers = list.collect {|field| label_for(field) }
    headers << (cost_type.try(:unit_plural) || l(:units))
    headers << l(:field_costs)
    sb.add_headers(headers)

    sb.add_format_option_to_column(headers.length - 1, :number_format => number_to_currency(0.00))
    sb.add_format_option_to_column(headers.length - 2, :number_format => "0.0")

    query.each_direct_result do |result|
      row = list.collect {|field| show_field field, result.fields[field.to_s] }
      row << show_result(result, result.fields['cost_type_id'].to_i) # units
      row << show_result(result, 0) # currency
      sb.add_row(row)
    end

    footer = [''] * list.size
    if show_result(query, 0) != show_result(query)
      footer += [show_result(query), show_result(query, 0)]
    else
      footer += ['', show_result(query)]
    end
    sb.add_row(footer) # footer

    sb
  end
end
