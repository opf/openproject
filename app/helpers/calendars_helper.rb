module CalendarsHelper
  def link_to_previous_month(year, month, options={})
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

    link_to_month(('&#171; ' + name), target_year, target_month, options)
  end

  def link_to_next_month(year, month, options={})
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

    link_to_month((name + ' &#187;'), target_year, target_month, options)
  end

  def link_to_month(link_name, year, month, options={})
    link_to_content_update(link_name, params.merge(:year => year, :month => month))
  end
end
