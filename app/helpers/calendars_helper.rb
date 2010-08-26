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

    project_id = options[:project].present? ? options[:project].to_param : nil
    link_target = calendar_path(:year => target_year, :month => target_month, :project_id => project_id)

    link_to_remote(('&#171; ' + name),
                   {:update => "content", :url => link_target, :method => :put},
                   {:href => link_target})
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

    project_id = options[:project].present? ? options[:project].to_param : nil
    link_target = calendar_path(:year => target_year, :month => target_month, :project_id => project_id)

    link_to_remote((name + ' &#187;'), 
                   {:update => "content", :url => link_target, :method => :put},
                   {:href => link_target})

  end
end
