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
        "wide-icon icon-money-time"
      else
        case applies[0]
        when :time_entries
          "wide-icon single-wide-icon icon-time"
        when :cost_entries
          "wide-icon single-wide-icon icon-money"
        end
      end
    end
  end
  
end
