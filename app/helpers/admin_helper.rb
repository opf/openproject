module AdminHelper
  def project_status_options_for_select(selected)
    options_for_select([[l(:label_all), ''], 
                        [l(:status_active), 1]], selected)
  end
end
