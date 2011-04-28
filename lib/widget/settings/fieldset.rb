class Widget::Settings::Fieldset < Widget::Base
  def render_with_options(options, &block)
    @type = options.delete(:type) || "filter"
    @id = "#{@type}-settings"
    @label = :"label_#{@type}"
    super(options, &block)
  end

  def render
    hash = self.hash
    content_tag :fieldset, :id => @id, :class => "collapsible collapsed" do
      content = maybe_with_help l(@label),
        :show_at_id => hash.to_s,
        :icon => { :class => "#{@type}-legend-icon" },
        :tooltip => { :class => "#{@type}-legend-tip" }
      html = content_tag :legend, content,
        {:onclick => "toggleFieldset(this);", :id => hash.to_s}, false #FIXME: onclick
      html + yield
    end
  end
end
