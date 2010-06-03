module BacklogsHelper
  
  def backlog_html_class(backlog)
    is_sprint?(backlog) ? l(:label_sprint_backlog) : l(:label_product_backlog)
  end
  
  def backlog_html_id(backlog)
    is_sprint?(backlog) ? "sprint_#{backlog.id}" : "product_backlog"
  end

  def backlog_id_or_empty(backlog)
    is_sprint?(backlog) ? backlog.id : ""
  end
  
  def date_or_nil(date)
    date.nil? ? '' : date.strftime('%Y-%m-%d')
  end
  
  def editable_if_sprint(backlog)
    "editable" if is_sprint?(backlog)
  end
  
  def is_sprint?(backlog)
    backlog.class.to_s.downcase=='sprint'
  end
  
  def name_or_default(backlog)
    is_sprint?(backlog) ? backlog.name : l(:label_Product_backlog)
  end
  
  def stories(backlog)
    backlog[:stories] || backlog.stories
  end
end
