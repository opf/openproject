##
# Usage: render_widget Widget::Help, :text
#
# Where :text is a i18n key.
class Widget::Help < Widget::Base
  dont_cache!

  def render
    id = "tip:#{@subject}"
    options = {:icon => {}, :tooltip => {}}
    options.merge!(yield) if block_given?
    sai = options[:show_at_id] ? ", show_at_id: '#{options[:show_at_id]}'" : ""

    icon = tag :img, :src => image_path('icon_info_red.gif'), :id => "target:#{@subject}"
    tip = content_tag_string :span, l(@subject), tip_config(options[:tooltip]), false
    script = content_tag :script,
      "new Tooltip('target:#{@subject}', 'tip:#{@subject}', {className: 'tooltip'#{sai}});",
      {:type => 'text/javascript'}, false
    target = content_tag :a, icon + tip, icon_config(options[:icon])
    write(target + script)
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
    options.mega_merge! :id => "tip:#{@subject}", :class => add_class
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
