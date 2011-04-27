class Widget::Settings::Fieldset < Widget::Base
  dont_cache!

  def render_with_options(options, &block)
    @type = options.delete(:type) || "filter"
    @id = "#{@type}-settings"
    @label = :"label_#{@type}"
    super(options, &block)
  end

  def render
    hash = self.hash
    write(content_tag :fieldset, :id => @id, :class => "collapsible collapsed" do
      html = content_tag :legend,
        :show_at_id => hash.to_s,
        :icon => "#{@type}-legend-icon",
        :tooltip => "#{@type}-legend-tip",
        :onclick => "toggleFieldset(this);", :id => hash.to_s do #FIXME: onclick
        maybe_with_help l(@label)
        l(@label)
      end
      html + yield
    end)
  end
end
