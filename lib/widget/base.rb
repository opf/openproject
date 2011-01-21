class Widget::Base < Widget
  attr_reader :engine

  def initialize(query)
    @query = query
    @engine = query.class
  end

  def render
    raise NotImplementedError,  "#render is missing in my subclass"
  end

  def render_with_options(options = {})
    if canvas = options[:to]
      canvas << "\n" << render
    else
      raise ArgumentError, "invalid options"
    end
  end
end
