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
  def help_text; end
  
  ##
  # Appends the Help Widget with this Widget's help text
  # if it is defined to the input.
  # If the help text is not defined the input is returned.
  def maybe_with_help(html, options = {})
    if help_text
      help = render_widget Widget::Controls::Help, help_text do
        options
      end
      html + help
    else
      html
    end
  end
end
