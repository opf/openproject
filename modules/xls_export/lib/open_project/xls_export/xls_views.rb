class OpenProject::XlsExport::XlsViews
  include Redmine::I18n
  include ActionView::Helpers::NumberHelper
  include ApplicationHelper
  include ReportingHelper
  include OpenProject::StaticRouting::UrlHelpers

  attr_accessor :spreadsheet, :query, :cost_type, :unit_id, :options

  # Overwrite a few mappings.
  def field_representation_map(key, value)
    case key.to_sym
    when :units                     then value.to_i
    when :spent_on                  then value
    when :activity_id               then mapped value, Enumeration, I18n.t(:caption_material_costs)
    when :project_id                then (I18n.t(:label_none) if value.to_i.zero?) or Project.find(value.to_i).name
    when :user_id, :assigned_to_id  then (I18n.t(:label_none) if value.to_i.zero?) or User.find(value.to_i).name
    when :work_package_id
      return I18n.t(:label_none) if value.to_i.zero?

      work_package = WorkPackage.find(value.to_i)
      "#{work_package.project.name + ' - ' if @project}#{work_package.type} ##{work_package.id}: #{work_package.subject}"
    else super(key, value)
    end
  end

  def show_result(row, unit_id = @unit_id, as_text = false)
    return super(row, unit_id) if as_text

    case unit_id
    when 0 then row.real_costs || 0
    else row.units
    end
  end

  def cost_type_unit_label(cost_type_id, cost_type_inst = nil, plural = true)
    case cost_type_id
    when -1 then l_hours(2).split[1..-1].join(" ") # get the plural for hours
    when 0  then Setting.plugin_openproject_costs['costs_currency']
    else cost_type_label(cost_type_id, cost_type_inst, plural)
    end
  end

  def serialize_query_without_hidden(query)
    serialized_query = query.serialize
    serialized_query[:filters] = serialized_query[:filters].reject do |_, options|
      options[:display] == false
    end
    serialized_query
  end

  def self.generate(opts)
    new.tap do |obj|
      obj.query = opts[:query]
      obj.cost_type = opts[:cost_type]
      obj.unit_id = opts[:unit_id]
      obj.options = opts
    end.generate
  end
end

# Load subclasses
require_relative './xls_views/cost_entry_table.xls'
require_relative './xls_views/simple_cost_report_table.xls'
require_relative './xls_views/cost_report_table.xls'
