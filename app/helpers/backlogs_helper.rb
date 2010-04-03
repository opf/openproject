module BacklogsHelper
  
  def backlog_html_class(backlog)
    is_sprint(backlog) ? "sprint backlog" : "product backlog"
  end
  
  def backlog_html_id(backlog)
    is_sprint(backlog) ? "sprint_#{backlog.id}" : "product_backlog"
  end
  
  def date_or_nil(date)
    date.nil? ? '' : date.strftime('%Y-%m-%d')
  end
  
  def editable_if_sprint(backlog)
    "editable" if is_sprint(backlog)
  end
  
  def is_sprint(backlog)
    backlog.class.to_s.downcase=='sprint'
  end
  
  def name_or_default(backlog)
    is_sprint(backlog) ? backlog.name : "Product Backlog"
  end
  
  def stories(backlog)
    backlog[:stories] || backlog.stories
  end
end
