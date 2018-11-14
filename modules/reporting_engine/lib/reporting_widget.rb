#-- copyright
# ReportingEngine
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require_dependency 'reporting_engine/helpers/reporting_helper'

class ReportingWidget < ActionView::Base
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::JavaScriptHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include ReportingHelper
  include Redmine::I18n

  attr_accessor :output_buffer, :controller, :config, :_content_for, :_routes, :subject

  def self.new(subject)
    super(subject).tap do |o|
      o.subject = subject
    end
  end

  def current_language
    ::I18n.locale
  end

  def protect_against_forgery?
    false
  end

  def method_missing(name, *args, &block)
    controller.send(name, *args, &block)
  rescue NoMethodError
    raise NoMethodError, "undefined method `#{name}' for #<#{self.class}:0x#{object_id}>"
  end

  module RenderWidgetInstanceMethods
    def render_widget(widget, subject, options = {}, &block)
      i = widget.new(subject)
      i.config = config
      i._routes = _routes
      i._content_for = @_content_for
      i.controller = respond_to?(:controller) ? controller : self
      i.request = request
      i.render_with_options(options, &block)
    end
  end
end

ActionView::Base.send(:include, ReportingWidget::RenderWidgetInstanceMethods)
ActionController::Base.send(:include, ReportingWidget::RenderWidgetInstanceMethods)
