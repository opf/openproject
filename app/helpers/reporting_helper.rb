module ReportingHelper
  ##
  # For a given CostQuery::Filter filter, return an array of hashes, that contain
  # the partials that should be rendered (:name) for that filter and necessary
  # parameters.
  # @param [CostQuery::Filter] the filter we want to render
  def html_elements(filter)
    return text_elements filter if CostQuery::Operator.string_operators.all? { |o| filter.available_operators.include? o }
    return date_elements filter if CostQuery::Operator.time_operators.all?   { |o| filter.available_operators.include? o }
    object_elements filter
  end

  def object_elements(filter)
    [
      {:name => :activate_filter, :filter_name => filter.underscore_name, :label => l(filter.label)},
      {:name => :operators, :filter_name => filter.underscore_name, :operators => filter.available_operators},
      {:name => :multi_values, :filter_name => filter.underscore_name, :values => filter.available_values}]
  end

  def date_elements(filter)
    [
      {:name => :activate_filter, :filter_name => filter.underscore_name, :label => l(filter.label)},
      {:name => :operators, :filter_name => filter.underscore_name, :operators => filter.available_operators},
      {:name => :date, :filter_name => filter.underscore_name}]
  end

  def text_elements(filter)
    [
      {:name => :activate_filter, :filter_name => filter.underscore_name, :label => l(filter.label)},
      {:name => :operators, :filter_name => filter.underscore_name, :operators => filter.available_operators},
      {:name => :text_box, :filter_name => filter.underscore_name}]
  end

  ##
  # For a given row, determine how to render it's contents according to usability and 
  # localization rules  
  def show_row(row)
    @show_row ||= Hash.new { |h,k| h[k] = {}}
    row.render do |key, value|
      @show_row[key][value] ||= begin
        case key.to_sym
        when :activity_id               then Enumeration.find(value.to_i).name
        when :project_id                then link_to_project Project.find(value.to_i)
        when :user_id, :assigned_to_id  then link_to_user User.find(value.to_i)
        when :tyear                     then value
        when :tweek                     then "#{l(:label_week)} ##{value}"
        when :tmonth                    then month_name(value.to_i)
        when :category_id               then IssueCategory.find(value.to_i).name
        when :cost_type_id              then CostType.find(value.to_i).name
        else "??? #{key}: #{value.inspect} ???"
        end
      end
    end
  end
end