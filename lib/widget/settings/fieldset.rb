class Widget::Settings::Fieldset < Widget::Base
  def render_with_options(options, &block)
    @type = options.delete(:type) || "filter"
    @id = "#{@type}-settings"
    @label = :"label_#{@type}"
    super(options, &block)
  end

  def render
    write(content_tag :fieldset, :id => @id, :class => "collapsible collapsed" do
      html = content_tag :legend, l(@label), :onclick => "toggleFieldset(this);" #FIXME: onclick
      html + yield
    end)
  end
end
