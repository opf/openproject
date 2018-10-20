class RailsCell < Cell::ViewModel
  include Escaped
  include ERB::Util
  include ApplicationHelper
  include ActionView::Helpers::TranslationHelper
  include SecureHeaders::ViewHelpers

  # Delegate to action_view
  delegates :action_view, :content_for

  self.view_paths = ['app/cells/views']

  # We don't include ActionView::Helpers wholesale because
  # this would override Cell's own render method and
  # subsequently break everything.

  ##
  # Defines options for this cell which can be used within the cell's template.
  # Options are passed to the cell during the render call.
  #
  # @param names [Array<String> | Hash<String, Any>] Either a list of names for options whose
  #                                                  default value is empty or a hash mapping
  #                                                  option names to default values.
  def self.options(*names)
    default_values = {}

    if names.size == 1 && names.first.is_a?(Hash)
      default_values = names.first
      names = default_values.keys
    end

    names.each do |name|
      define_method(name) do
        options[name] || default_values[name]
      end
    end
  end

  def show
    # Set the _request from AS::Controller that doesn't get passed into the rails cell.
    # Workaround for when using middlewares such as SecureHeaders that relies on it,
    # but don't use the request method itself.
    @_request = request

    render
  end

  def controller
    context[:controller]
  end

  def action_view
    context[:action_view]
  end

  def protect_against_forgery?
    controller.send(:protect_against_forgery?)
  end

  def form_authenticity_token(*args)
    controller.send(:form_authenticity_token, *args)
  end

  # override cell-erb's behaviour to not escape
  # https://github.com/trailblazer/cells-erb/tree/v0.1.0#html-escaping
  def content_tag(name, content_or_options_with_block = nil, options = nil, escape = true, &block)
    super
  end

  def request
    controller.request
  end
end
