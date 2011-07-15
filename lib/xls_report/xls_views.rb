class XlsViews
  include Redmine::I18n
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper
  include ReportingHelper
  attr_accessor :spreadsheet, :query, :cost_type, :unit_id, :options

  # Overwrite a few mappings.
  def field_representation_map(key, value)
    case key.to_sym
    when :units                     then value.to_i
    when :spent_on                  then value
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

  def show_result(row, unit_id = @unit_id, as_text = false)
    return super(row, unit_id) if as_text
    case unit_id
    when 0 then row.real_costs ? row.real_costs : '-'
    else row.units
    end
  end

  def cost_type_unit_label(cost_type_id, cost_type_inst = nil, plural = true)
    case cost_type_id
    when -1 then l_hours(2).split[1..-1].join(" ") # get the plural for hours
    when 0  then Setting.plugin_redmine_costs['costs_currency']
    else cost_type_label(cost_type_id, cost_type_inst, plural)
    end
  end

  def self.generate(opts)
    self.new.tap do |obj|
      obj.query = opts[:query]
      obj.cost_type = opts[:cost_type]
      obj.unit_id = opts[:unit_id]
      obj.options = opts
    end.generate
  end
end

# Load subclasses
require_dependency 'xls_report/xls_views/cost_entry_table.xls'
require_dependency 'xls_report/xls_views/simple_cost_report_table.xls'
require_dependency 'xls_report/xls_views/cost_report_table.xls'
