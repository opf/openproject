module ReportingHelper
  ##
  # For a given CostQuery::Filter filter, return an array of hashes, that contain
  # the partials that should be rendered (:name) for that filter and necessary
  # parameters.
  # @param [CostQuery::Filter] the filter we want to render
  def html_elements(filter)
    [
      {:name=>'activate_filter'},
      {:name=>'text', :text=>'foo'}]
  end
end