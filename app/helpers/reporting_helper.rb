module ReportingHelper
  ##
  # For a given CostQuery::Filter filter, return an array of hashes, that contain
  # the partials that should be rendered (:name) for that filter and necessary
  # parameters.
  # @param [CostQuery::Filter] the filter we want to render
  def html_elements(filter)
    [
      {:name => :activate_filter, :filter_name => filter.short_name, :label => l(:field_activity)}, #FIXME: change label not to be activity only
      {:name => :operators, :filter_name => filter.short_name, :operators => filter.available_operators},
      {:name => :multi_values, :filter_name => filter.short_name, :values => filter.available_values}]
  end
end