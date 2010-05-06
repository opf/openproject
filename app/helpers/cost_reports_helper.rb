module CostReportsHelper
  include QueriesHelper
  
  def operators_for_select(type_name)
    CostQuery.filter_types[type_name][:operators].collect {|o| [l(CostQuery.operators[o][:label]), o]}
  end
  
  def scope_icon_class(filter)
    case filter.scope
    when :issues
      "wide-icon single-wide-icon icon-ticket"
    when :costs
      applies =  @query.available_filters[filter.scope][filter.column_name][:applies]
      return "wide-icon" if applies.nil? || applies.empty?
      if applies.length > 1
        "wide-icon icon-pieces-time"
      else
        case applies[0]
        when :time_entries
          "wide-icon single-wide-icon icon-time"
        when :cost_entries
          "wide-icon single-wide-icon icon-pieces"
        end
      end
    end
  end
  
  def js_reorder_links(name, function)
    link_to_function(image_tag('2uparrow.png',   :alt => l(:label_sort_highest)), "#{function}('#{escape_javascript(name)}', 'highest')", :title => l(:label_sort_highest)) +
    link_to_function(image_tag('1uparrow.png',   :alt => l(:label_sort_higher)),  "#{function}('#{escape_javascript(name)}', 'higher')", :title => l(:label_sort_higher)) +
    link_to_function(image_tag('1downarrow.png', :alt => l(:label_sort_lower)),   "#{function}('#{escape_javascript(name)}', 'lower')", :title => l(:label_sort_lower)) +
    link_to_function(image_tag('2downarrow.png', :alt => l(:label_sort_lowest)),  "#{function}('#{escape_javascript(name)}', 'lowest')", :title => l(:label_sort_lowest))
  end
  
  
  def element_hidden_warning()
    # FIXME: Wanring has also to be generated if right is not granted in one of the subprojects only
    unless User.current.allowed_to?(:view_cost_entries, @project, :for => nil) && 
      User.current.allowed_to?(:view_time_entries, @project, :for => nil) &&
      User.current.allowed_to?(:view_cost_rates, @project, :for => nil) &&
      User.current.allowed_to?(:view_hourly_rates, @project, :for => nil)
      content_tag :div, l(:text_warning_hidden_elements), :class => "flash warning"
    end
  end
end
