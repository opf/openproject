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
    when :spent_on                  then value.iso8601
    when :activity_id               then mapped value, Enumeration, I18n.t("placeholders.default")
    when :project_id                then project_representation(value)
    when :user_id, :assigned_to_id  then user_representation(value)
    when :work_package_id           then work_package_representation(value)
    when :entity_gid                then entity_global_id_representation(value)
    else super
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
    when 0  then Setting.costs_currency
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
    "#,##0.00 [$#{Setting.costs_currency}]"
  end

  def number_format
    "0.00"
  end

  def date_format
    @date_format ||= Spreadsheet::Format.new(
      number_format: "yyyy-mm-dd",
      horizontal_align: :left,
      vertical_align: :top
    )
  end

  def project_representation(value)
    ar_presentation(Project, value, &:name)
  end

  def user_representation(value)
    ar_presentation(User, value, &:name)
  end

  def work_package_representation(value)
    ar_presentation(WorkPackage, value) do |work_package|
      "#{work_package.type} #{work_package.formatted_id}: #{work_package.subject}"
    end
  end

  def entity_global_id_representation(value)
    # TODO: All possible time entry associations need to be checked here
    entity = GlobalID::Locator.locate(value, only: TimeEntry::ALLOWED_ENTITY_TYPES.map(&:safe_constantize))
    if entity.is_a?(WorkPackage)
      "#{entity.type} #{entity.formatted_id}: #{entity.subject}"
    elsif entity.is_a?(Meeting)
      "#{Meeting.model_name.human} ##{entity.id}: #{entity.title}"
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
