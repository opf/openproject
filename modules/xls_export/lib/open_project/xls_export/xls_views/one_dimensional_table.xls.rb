class OpenProject::XlsExport::XlsViews::OneDimensionalTable < OpenProject::XlsExport::XlsViews
  def generate
    spreadsheet = OpenProject::XlsExport::SpreadsheetBuilder.new(I18n.t(:label_money))
    default_query = serialize_query_without_hidden(@query)

    available_cost_type_tabs(options[:cost_types]).each_with_index do |(unit_id, name), idx|
      setup_query_for_tab(default_query, unit_id)

      spreadsheet.worksheet(idx, name)
      build_spreadsheet(spreadsheet)
    end

    spreadsheet
  end

  def setup_query_for_tab(query, unit_id)
    @query = CostQuery.deserialize(query)
    @cost_type = nil
    @unit_id = unit_id

    if @unit_id != 0
      @query.filter :cost_type_id, operator: '=', value: @unit_id.to_s
      @cost_type = CostType.find(unit_id) if unit_id.positive?
    end
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
    raise NotImplementedError
  end

  def build_cost_rows(spreadsheet)
    query.each_direct_result do |result|
      spreadsheet.add_row(cost_row(result))
    end
  end

  def cost_row(result)
    raise NotImplementedError
  end

  def build_footer(spreadsheet)
    raise NotImplementedError
  end

  def headers
    raise NotImplementedError
  end

  def currency_format
    "#,##0.00 [$#{Setting.plugin_openproject_costs['costs_currency']}]"
  end

  def number_format
    "0.0"
  end
end
