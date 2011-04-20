class Widget::Base < Widget
  attr_reader :engine, :output

  def self.dont_cache!
    @dont_cache = true
  end

  def self.dont_cache?
    @dont_cache
  end

  def initialize(query)
    @query = query
    @engine = query.class
  end

  ##
  # Write a string to the canvas. The string is marked as html_safe.
  # This will write twice, if @cache_output is set.
  def write(str)
    str ||= ""
    @output ||= "".html_safe
    @output.write str.html_safe
    @cache_output.write(str.html_safe) if @cache_output
  end

  ##
  # Render this widget. Abstract method. Needs to call #write at least once
  def render
    raise NotImplementedError,  "#render is missing in my subclass #{self.class}"
  end

  ##
  # Render this widget, passing options.
  # Available options:
  #   :to => canvas - The canvas (streaming or otherwise) to render to. Has to respond to #write
  def render_with_options(options = {}, &block)
    set_canvas(options[:to]) if options.has_key? :to
    render_with_cache(options, &block)
    @output
  end

  def cache_key
    subject.cache_key
  end

  def cached?
    cache? and Rails.cache.exist?(cache_key)
  end

  private

  def cache?
    !self.class.dont_cache?
  end


  ##
  # Render this widget or serve it from cache
  def render_with_cache(options = {}, &block)
    if cached?
      write Rails.cache.fetch(cache_key)
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
