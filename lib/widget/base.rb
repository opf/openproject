class Widget::Base < Widget
  attr_reader :engine, :output

  def initialize(query)
    @query = query
    @engine = query.class
    @output = "".html_safe
  end

  def write(str)
    @output.write str
  end

  def render
    raise NotImplementedError,  "#render is missing in my subclass"
  end

  def render_with_options(options = {}, &block)
    if canvas = options[:to]
      @output = canvas
    end
    result = render(&block)
    if @output.respond_to? :to_str and @output.empty? # FIXME: Transitional support
      @output += "\n#{result}".html_safe
    end
    @output
  end
end
