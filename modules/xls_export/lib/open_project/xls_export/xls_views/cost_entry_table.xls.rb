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
    set_title(spreadsheet)

    build_header(spreadsheet)
    format_columns(spreadsheet)
    build_cost_rows(spreadsheet)
    build_footer(spreadsheet)

    spreadsheet
  end

  def set_title(spreadsheet)
    spreadsheet.add_title("#{@project.name + ' >> ' if @project}#{I18n.t(:cost_reports_title)} (#{format_date(Date.today)})")
  end

  def build_header(spreadsheet)
    spreadsheet.add_headers(headers)
  end

  def format_columns(spreadsheet)
    spreadsheet.add_format_option_to_column(headers.length - 3, number_format: "0.0")
    spreadsheet.add_format_option_to_column(headers.length - 1, number_format: "#,##0.00 [$#{Setting.plugin_openproject_costs['costs_currency']}]")
  end

  def build_cost_rows(spreadsheet)
    query.each_direct_result do |result|
      row = cost_entry_attributes.map { |field| show_field field, result.fields[field.to_s] }
      current_cost_type_id = result.fields['cost_type_id'].to_i

      row << show_result(result, current_cost_type_id) # units
      row << cost_type_label(current_cost_type_id, @cost_type) # cost type
      row << show_result(result, 0) # costs/currency

      spreadsheet.add_row(row)
    end
  end

  def build_footer(spreadsheet)
    footer = [''] * cost_entry_attributes.size
    footer += if show_result(query, 0) != show_result(query)
                [show_result(query), '', show_result(query, 0)]
              else
                ['', '', show_result(query)]
              end
    spreadsheet.add_row(footer) # footer
  end

  def headers
    cost_entry_attributes
      .map { |field| label_for(field) }
      .concat([CostEntry.human_attribute_name(:units), CostType.model_name.human, CostEntry.human_attribute_name(:costs)])
  end

  def cost_entry_attributes
    %i[spent_on user_id activity_id issue_id comments project_id]
  end
end
