class Widget::Filters::Label < Widget::Filters::Base
  def render
    content_tag :td, :width => 150 do
      box = tag :input, :id => "cb_#{filter_class.underscore_name}", :name => "fields[]",
          :onclick => "toggle_filter('#{filter_class.underscore_name}');",
          :type => "checkbox", :value => filter_class.underscore_name
      lbl = content_tag :label, :id => filter_class.underscore_name do
        l(filter_class.label)
      end
      box + lbl
    end
  end
end
