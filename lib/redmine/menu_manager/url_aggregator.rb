class Redmine::MenuManager::UrlAggregator
  include WatchersHelper
  include Rails.application.routes.url_helpers
  include Redmine::I18n
  include ActionView::Helpers::UrlHelper
  include AccessibilityHelper


  attr_reader :controller,
              :url,
              :options

  def initialize(url, options = {})
    @url = url
    @options = options
  end

  def call(locals = {})
    @controller = locals.delete(:controller)

    full_url = case url
               when Hash
                 url.inject({}) do |h, (k, v)|
                   h[k] = if locals.has_key?(v) && locals[v].is_a?(ActiveRecord::Base)
                            locals[v].id
                          else
                            v
                          end

                   h
                 end
               when Symbol
                 send(url)
               else
                 url
               end

    text = you_are_here_info(locals[:selected]) + caption

    link_to text, full_url, html_options(locals)
  end

  private

  def caption
    c = @options[:caption]

    if c.nil?
      l_or_humanize("name", :prefix => 'label_')
    else
      c.is_a?(Symbol) ? l(c) : c
    end
  end

  def html_options(options={})
    debugger if options[:selected]
    if options[:selected]
      o = @options[:html_options].dup
      o[:class] += ' selected'
      o
    else
      options[:html_options]
    end
  end
end
