# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

module OpenProject
  module OpenTelemetry
    module_function

    def enabled?
      OpenProject::Configuration.opentelemetry_enabled?
    end

    def exception_handler(_message, log_context = {})
      return unless enabled?

      exception = log_context[:exception]
      return if exception.nil?

      trace_exception(exception, log_context)
    end

    def trace_exception(exception, context = {})
      current_span = ::OpenTelemetry::Trace.current_span
      if current_span.context.valid?
        # Add exception to current span
        current_span.record_exception(exception)
        set_span_attributes(current_span, tags(context))
      else
        # Create a new span for the exception if no current span
        tracer = ::OpenTelemetry.tracer_provider.tracer("openproject")
        tracer.in_span("exception") do |span|
          span.record_exception(exception)
          set_span_attributes(span, tags(context))
        end
      end
    end

    ##
    # Add current user and other stateful attributes to the current span
    # @param context A hash of context, such as passing in the current controller or request
    def tag_request(context = {})
      return unless enabled?

      current_span = ::OpenTelemetry::Trace.current_span
      return unless current_span.context.valid?

      attributes = tags(context)
      set_span_attributes(current_span, attributes)
    end

    ##
    # Tags to be added for OpenTelemetry spans
    def tags(context)
      OpenProject::Logging.extend_payload!(default_payload, context)
    end

    ##
    # Default payload to add for OpenTelemetry spans
    def default_payload
      {
        "openproject.locale" => I18n.locale.to_s,
        "openproject.version" => OpenProject::VERSION.to_semver,
        "openproject.core_hash" => OpenProject::VERSION.revision,
        "openproject.core_version" => OpenProject::VERSION.core_sha,
        "openproject.product_version" => OpenProject::VERSION.product_sha
      }.compact
    end

    ##
    # Add attributes to the current span
    # @param attributes Hash of attributes to add
    def add_attributes(attributes)
      return unless enabled?

      current_span = ::OpenTelemetry::Trace.current_span
      return unless current_span.context.valid?

      set_span_attributes(current_span, attributes)
    end

    ##
    # Add an event to the current span
    # @param name Event name
    # @param attributes Hash of attributes for the event
    def add_event(name, attributes = {})
      return unless enabled?

      current_span = ::OpenTelemetry::Trace.current_span
      return unless current_span.context.valid?

      current_span.add_event(name, attributes)
    end

    ##
    # Helper method to set multiple attributes on a span
    # OpenTelemetry uses set_attribute (singular) not set_attributes (plural)
    def set_span_attributes(span, attributes)
      attributes.each do |key, value|
        span.set_attribute(key.to_s, value.to_s)
      end
    end

    # Determine process type
    def process_type # rubocop:disable Metrics/PerceivedComplexity
      if defined?(Rails::Server)
        "web"
      elsif defined?(Rails::Console)
        "console"
      elsif defined?(Rails::Runner)
        "runner"
      elsif defined?(Rails::Generators)
        "generator"
      elsif defined?(Rake) && Rake.application.top_level_tasks.any?
        "rake"
      elsif defined?(GoodJob::CLI) && GoodJob::CLI.within_exe?
        "worker"
      else
        "unknown"
      end
    end
  end
end
