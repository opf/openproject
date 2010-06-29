module ReportingHelper
  ##
  # For a given CostQuery::Filter f, return an array of hashes, that contain
  # the partials that should be rendered (:name) for that filter and necessary
  # parameters.
  # @param [CostQuery::Filter] the filter which we want render
  def html_elements(f)
    [
      {:name=>'activate_filter'},
      {:name=>'text', :text=>'foo'}]
  end
end