module CalendarsHelper
  def link_to_previous_month(year, month)
    target_year, target_month = if month == 1
                                  [year - 1, 12]
                                else
                                  [year, month - 1]
                                end
    
    name = if target_month == 12
             "#{month_name(target_month)} #{target_year}"
           else
             "#{month_name(target_month)}"
           end
    
     link_to_remote ('&#171; ' + name),
                        {:update => "content", :url => { :year => target_year, :month => target_month }},
                        {:href => url_for(:action => 'show', :year => target_year, :month => target_month)}
  end

  def link_to_next_month(year, month)
    target_year, target_month = if month == 12
                                  [year + 1, 1]
                                else
                                  [year, month + 1]
                                end

    name = if target_month == 1
             "#{month_name(target_month)} #{target_year}"
           else
             "#{month_name(target_month)}"
           end

    link_to_remote (name + ' &#187;'), 
                        {:update => "content", :url => { :year => target_year, :month => target_month }},
                        {:href => url_for(:action => 'show', :year => target_year, :month =>target_month)}

  end
end
