class OpenProject::XlsExport::XlsViews::CostEntryTable < OpenProject::XlsExport::XlsViews
  def generate
    spreadsheet = OpenProject::XlsExport::SpreadsheetBuilder.new(I18n.t(:label_money))
    default_query = serialize_query_without_hidden(@query)

    available_cost_type_tabs(options[:cost_types]).each_with_index do |ary, idx|
      @query = CostQuery.deserialize(default_query)
      @cost_type = nil
      @unit_id = ary.first
      name = ary.last

      if @unit_id != 0
        @query.filter :cost_type_id, operator: '=', value: @unit_id.to_s
        @cost_type = CostType.find(unit_id) if unit_id.positive?
      end

      spreadsheet.worksheet(idx, name)
      build_spreadsheet(spreadsheet)
    end
    spreadsheet
  end

  def build_spreadsheet(spreadsheet)
    spreadsheet.add_title("#{@project.name + " >> " if @project}#{I18n.t(:cost_reports_title)} (#{format_date(Date.today)})")

    list = %i[spent_on user_id activity_id issue_id comments project_id]
    headers = list.collect { |field| label_for(field) }
    headers << I18n.t(:units)
    headers << I18n.t(:field_cost_type)
    headers << I18n.t(:field_costs)
    spreadsheet.add_headers(headers)

    spreadsheet.add_format_option_to_column(headers.length - 1, number_format: number_to_currency(0.00))
    spreadsheet.add_format_option_to_column(headers.length - 2, number_format: "0.0")

    query.each_direct_result do |result|
      row = list.collect { |field| show_field field, result.fields[field.to_s] }
      current_cost_type_id = result.fields['cost_type_id'].to_i

      row << show_result(result, current_cost_type_id) # units
      row << cost_type_label(current_cost_type_id, @cost_type) # cost type
      row << show_result(result, 0) # costs/currency

      spreadsheet.add_row(row)
    end

    footer = [''] * list.size
    footer += if show_result(query, 0) != show_result(query)
                [show_result(query), '', show_result(query, 0)]
              else
                ['', '', show_result(query)]
              end
    spreadsheet.add_row(footer) # footer

    spreadsheet
  end
end
