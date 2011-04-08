##
# Usgae: render_widget Widget::Controls::Help, :text
#
# Where :text is a i18n key.
class Widget::Controls::Help < Widget::Base
  def render
    id = "tip:#{@query}"
    options = {:icon => {}, :tooltip => {}}
    options.merge!(yield) if block_given?
    icon = tag :img, :src => '/images/icon_info_red.gif', :id => "target:#{@query}"
    tip = content_tag_string :div, l(@query), tip_config(options[:tooltip]), false
    script = content_tag_string :script, "new Tooltip('target:#{@query}', 'tip:#{@query}', {className: 'tooltip'});",
      {:type => 'text/javascript'}, false
    target = content_tag :a, icon + tip, icon_config(options[:icon])
    target + script
  end

  def icon_config(options)
    add_class = lambda do |cl|
      if cl
        "help #{cl}"
      else
        "help"
      end
    end
    options.mega_merge! :href => '#', :class => add_class
  end

  def tip_config(options)
    add_class = lambda do |cl|
      if cl
        "#{cl} tooltip"
      else
        "tooltip"
      end
    end
    options.mega_merge! :id => "tip:#{@query}", :class => add_class
  end
end

class Hash
  def mega_merge!(hash)
    hash.each do |key, value|
      if value.kind_of?(Proc)
        self[key] = value.call(self[key])
      else
        self[key] = value
      end
    end
    self
  end
end
