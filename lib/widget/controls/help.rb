##
# Usgae: render_widget Widget::Controls::Help, :text
#
# Where :text is a i18n key.
class Widget::Controls::Help < Widget::Base
  def render
    options = {:icon => {}, :tooltip => {}}
    options.merge!(yield) if block_given?
    icon = tag :img, :src => '/images/help.png'
    span = content_tag_string :span, l(@query), options[:tooltip], false
    hull = content_tag :div, span
    icon_options = icon_config(options[:icon])
    content_tag :a, icon + hull, icon_options
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
