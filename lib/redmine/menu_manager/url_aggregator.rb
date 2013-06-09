class Redmine::MenuManager::UrlAggregator
  include WatchersHelper
  include Rails.application.routes.url_helpers
  include Redmine::I18n
  include ActionView::Helpers::UrlHelper

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

    link_to options[:caption], full_url
  end
end
