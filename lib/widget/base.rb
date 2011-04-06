class Widget::Base < Widget
  attr_reader :engine, :output

  def initialize(query)
    @query = query
    @engine = query.class
  end

  def write(str)
    @output ||= "".html_safe
    @output.write str.html_safe
    @cache_output.write(str.html_safe) if @cache_output
  end

  def render
    raise NotImplementedError,  "#render is missing in my subclass"
  end

  def render_with_options(options = {}, &block)
    set_canvas(options[:to]) if options.has_key? :to
    render_with_cache(options, &block)
    @output
  end

  def cache_key
    "#{self.class.name}/#{subject.hash}"
  end

  def render_with_cache(options = {}, &block)
    if Rails.cache.exist? cache_key
      Rails.cache.fetch(cache_key)
    else
      render(&block)
      Rails.cache.write(cache_key, @cache_output || @output)
    end
  end

  ##
  # Set the canvas. If the canvas object isn't a string (e.g. cannot be cached easily),
  # a @cache_output String is created, that will mirror what is being written to the canvas.
  def set_canvas(canvas)
    unless canvas.respond_to? :to_str
      @cache_output = @output || "".html_safe
    end
    @output = canvas
  end
end
