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
    when :project_id                then project_representation(value)
    when :user_id, :assigned_to_id  then user_representation(value)
    when :work_package_id           then work_package_representation(value)
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

  def set_title
    spreadsheet.add_title(
      "#{@project.name + ' >> ' if @project}#{I18n.t(:label_cost_report_plural)} (#{format_date(Date.today)})"
    )
  end

  def currency_format
    "#,##0.00 [$#{Setting.plugin_openproject_costs['costs_currency']}]"
  end

  def number_format
    "0.00"
  end

  def project_representation(value)
    ar_presentation(Project, value, &:name)
  end

  def user_representation(value)
    ar_presentation(User, value, &:name)
  end

  def work_package_representation(value)
    ar_presentation(WorkPackage, value) do |work_package|
      "#{work_package.type} ##{work_package.id}: #{work_package.subject}"
    end
  end

  def ar_presentation(klass, id)
    record = klass.find_by(id: id.to_i)

    if record
      yield record
    else
      I18n.t(:label_none)
    end
  end
end
