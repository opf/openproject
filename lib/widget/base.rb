class Widget::Base < Widget
  attr_reader :engine, :output

  def initialize(query)
    @query = query
    @engine = query.class
  end

  def write(str)
    @output ||= "".html_safe
    @output.write str.html_safe
  end

  def render
    raise NotImplementedError,  "#render is missing in my subclass"
  end

  def render_with_options(options = {}, &block)
    @output = options[:to] if options.has_key? :to
    render_with_cache(options, &block)
    @output
  end

  def render_with_cache(options = {}, &block)
    if Rails.cache.exist? cache_key
      Rails.cache.fetch(cache_key)
    else
      render(&block)
      Rails.cache.write(cache_key, @output)
    end
  end

  def cache_key
    "#{self.class.name}/#{subject.hash}"
  end
end
