class Widget::Base < Widget
  attr_reader :engine

  def initialize(query)
    @query = query
    @engine = query.class
  end

  def render
    raise NotImplementedError,  "#render is missing in my subclass"
  end

  def render_with_options(options = {}, &block)
    help_text = options[:help_text]
    if canvas = options[:to]
      canvas << "\n" << render(&block)
    else
      render(&block)
    end
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

  ##
  # Appends the Help Widget with this Widget's help text
  # if it is defined to the input.
  # If the help text is not defined the input is returned.
  def maybe_with_help(html, options = {})
    text = options[:text]
    text ||= help_text unless options[:ignore_default]
    if text
      help = render_widget Widget::Controls::Help, text do
        options
      end
      html + help
    else
      html
    end
  end
end
