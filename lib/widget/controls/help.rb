##
# Usgae: render_widget Widget::Controls::Help, :text
#
# Where :text is a i18n key.
class Widget::Controls::Help < Widget::Base
  def render
    icon = tag :img, :src => '/images/help.png', :alt => '?'
    span = content_tag_string :span, l(@query), {}, false
    content_tag :a, icon + span, :href => "#", :class => "help"
  end
end