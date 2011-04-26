class Widget < ActionView::Base
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::JavaScriptHelper

  attr_accessor :output_buffer, :controller, :config, :_content_for, :_routes, :subject

  extend ProactiveAutoloader

  def self.new(subject)
    super(subject).tap do |o|
      o.subject = subject
    end
  end

  # FIXME: There's a better one in ReportingHelper, remove this one
  def l(s)
    ::I18n.t(s.to_sym, :default => s.to_s.humanize)
  end

  def current_language
    ::I18n.locale
  end

  def protect_against_forgery?
    false
  end

  def method_missing(name, *args, &block)
    begin
      controller.send(name, *args, &block)
    rescue NoMethodError
      throw NoMethodError, "undefined method `#{name}' for #<#{self.class}:0x#{self.object_id}>"
    end
  end

  module RenderWidgetInstanceMethods
    def render_widget(widget, subject, options = {}, &block)
      i = widget.new(subject)
      if Rails.version.start_with? "3"
        i.config = config
        i._routes = _routes
      else
        i.output_buffer = ""
      end
      i._content_for = @_content_for
      i.controller = respond_to?(:controller) ? controller : self
      i.render_with_options(options, &block)
    end
  end
end

ActionView::Base.send(:include, Widget::RenderWidgetInstanceMethods)
ActionController::Base.send(:include, Widget::RenderWidgetInstanceMethods)
if Rails.version.start_with? "2"
  class ::String; def html_safe; self; end; end
end
class ::String; def write(s); concat(s); end; end
