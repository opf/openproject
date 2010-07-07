module ReportingHelper
  ##
  # For a given CostQuery::Filter filter, return an array of hashes, that contain
  # the partials that should be rendered (:name) for that filter and necessary
  # parameters.
  # @param [CostQuery::Filter] the filter we want to render
  def html_elements(filter)
    return text_elements filter if CostQuery::Operator.string_operators.all? { |o| filter.available_operators.include? o }
    return date_elements filter if CostQuery::Operator.date_operators.all?   { |o| filter.available_operators.include? o }
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
    row.render do |key, value|
      case key.to_sym
      when :project_id then "Project ##{value}: #{Project.find(value.to_i).name}"
      when :user_id then link_to_user User.find(value)
      when :tyear then value
      when :tweek then 
        if value.to_i == Date.today.cweek
          l(:label_this_week)
        elsif value.to_i == (Date.today.cweek - 1)
          l(:label_last_week)
        else
          "#{l(:label_week)} ##{value}"
        end
      else "#{key}: #{value}"
      end
    end
  end
end