module RbMasterBacklogsHelper
  unloadable
  include Redmine::I18n
  
  def backlog_html_class(backlog)
    is_sprint?(backlog) ? "sprint backlog" : "product backlog"
  end
  
  def backlog_html_id(backlog)
    is_sprint?(backlog) ? "sprint_#{backlog.id}" : "product_backlog"
  end

  def backlog_id_or_empty(backlog)
    is_sprint?(backlog) ? backlog.id : ""
  end

  def backlog_menu(is_sprint, items = [])
    html = %{
      <div class="menu">
        <div class="icon ui-icon ui-icon-carat-1-s"></div>
        <ul class="items">
    }
    items.each do |item|
      item[:condition] = true unless item.has_key?(:condition)
      if item[:condition] && ( (is_sprint && item[:for] == :sprint) ||
                               (!is_sprint && item[:for] == :product) ||
                               (item[:for] == :both) )
        html += %{ <li class="item">#{item[:item]}</li> }
      end
    end
    html += %{
        </ul>
      </div>
    }
  end
  
  def date_or_nil(date)
    date.blank? ? '' : date.strftime('%Y-%m-%d')
  end
  
  def editable_if_sprint(backlog)
    "editable" if is_sprint?(backlog)
  end
  
  def is_sprint?(backlog)
    backlog.class.to_s.downcase=='sprint'
  end

  def menu_link(label, options = {})
    # options[:class] = "pureCssMenui"
    link_to(label, options)
  end
  
  def name_or_default(backlog)
    is_sprint?(backlog) ? backlog.name : l(:label_Product_backlog)
  end
  
  def stories(backlog)
    backlog[:stories] || backlog.stories
  end
end
