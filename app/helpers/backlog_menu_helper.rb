module BacklogMenuHelper
  unloadable

  def backlog_menu(is_sprint, items = [])
    html = %{
      <ul class="actions pureCssMenu pureCssMenum">
          <li class="pureCssMenui">
              <a class="pureCssMenui" href="#"><span class="ui-icon ui-icon-triangle-1-s"></span></a>
              <ul class="pureCssMenum">
    }
    items.each do |item|
      item[:condition] = true if item[:condition].nil?
      if item[:condition] && ( (is_sprint && item[:for] == :sprint) ||
                               (!is_sprint && item[:for] == :product) ||
                               (item[:for] == :both) )
        html += %{ <li class="pureCssMenui">#{item[:item]}</li> }
      end
    end
    html += %{
              </ul>
          </li>
      </ul>
    }
  end

  def menu_link(label, options = {})
    # options[:class] = "pureCssMenui"
    link_to(label, options)
  end

end
