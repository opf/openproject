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
    project_id = options[:project].present? ? options[:project].to_param : nil

    link_target = calendar_path(:year => year, :month => month, :project_id => project_id)

    link_to_remote(link_name,
                   {:update => "content", :url => link_target, :method => :put},
                   {:href => link_target})

  end
  
end
