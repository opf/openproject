require 'digest/sha1'

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
    @options = {}
  end

  ##
  # Write a string to the canvas. The string is marked as html_safe.
  # This will write twice, if @cache_output is set.
  def write(str)
    str ||= ""
    @output ||= "".html_safe
    @output.write str.html_safe
    @cache_output.write(str.html_safe) if @cache_output
    str.html_safe
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
    @help_text = options[:help_text]
    set_canvas(options.delete(:to)) if options.has_key? :to
    @options = options
    render_with_cache(options, &block)
    @output
  end

  def cache_key
    subject.cache_key
  end

  ##
  # An optional help text. If defined the Help Widget
  # displaying the given text is going to be placed
  # next to this Widget, if it supports that.
  def help_text
    @help_text
  end

  def help_text=(text)
    @help_text = text
  end

  def cache_key
    @cache_key ||= Digest::SHA1::hexdigest begin
      if subject.respond_to? :cache_key
        "#{self.class.name.demodulize}/#{subject.cache_key}/#{@options.sort_by(&:to_s)}"
      else
        subject.inspect
      end
    end
  end

  def cached?
    cache? && Rails.cache.exist?(cache_key)
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
      Rails.cache.write(cache_key, @cache_output || @output) if cache?
    end
  end

  ##
  # Set the canvas. If the canvas object isn't a string (e.g. cannot be cached easily),
  # a @cache_output String is created, that will mirror what is being written to the canvas.
  def set_canvas(canvas)
    @cache_output = "".html_safe
    @output = canvas
  end

  ##
  # Appends the Help Widget with this Widget's help text.
  # If no help-text was given and no default help-text is set,
  # the given default html will be printed instead.
  # Params:
  #  - html
  #  - options-hash
  #    - :fallback_html (string, default: '') - the html code to render if no help-text was found
  #    - :help_text (string) - the help text to render
  #    - :instant_write (bool, default: true) - wether to write
  #          the help-widget instantly to the output-buffer.
  #          If set to false you should care to save the rendered text.
  def maybe_with_help(options = {})
    options[:instant_write] = true if options[:instant_write].nil?
    options[:fallback_html] ||= ''
    output = "".html_safe
    if text = options[:help_text] || help_text
      output += render_widget Widget::Help, text do
        options
      end
    else
      output += options[:fallback_html]
    end
    write output if options[:instant_write]
    output.html_safe
  end
end
