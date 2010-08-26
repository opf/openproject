module CalendarsHelper
  def link_to_previous_month(year, month)
     link_to_remote ('&#171; ' + (month==1 ? "#{month_name(12)} #{year-1}" : "#{month_name(month-1)}")), 
                        {:update => "content", :url => { :year => (month==1 ? year-1 : year), :month =>(month==1 ? 12 : month-1) }},
                        {:href => url_for(:action => 'show', :year => (month==1 ? year-1 : year), :month =>(month==1 ? 12 : month-1))}
  end

  def link_to_next_month(year, month)
    link_to_remote ((month==12 ? "#{month_name(1)} #{year+1}" : "#{month_name(month+1)}") + ' &#187;'), 
                        {:update => "content", :url => { :year => (month==12 ? year+1 : year), :month =>(month==12 ? 1 : month+1) }},
                        {:href => url_for(:action => 'show', :year => (month==12 ? year+1 : year), :month =>(month==12 ? 1 : month+1))}

  end
end
