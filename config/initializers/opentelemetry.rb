# frozen_string_literal: true

#-- copyright
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../../lib_static/open_project/opentelemetry"
require_relative "../../lib_static/open_project/opentelemetry/excon_hash_query"

Rails.application.configure do
  if OpenProject::Configuration.opentelemetry_enabled?

    require "opentelemetry/sdk"
    require "opentelemetry-exporter-otlp"

    # Available Ruby instrumentations can be found here:
    # https://github.com/open-telemetry/opentelemetry-ruby-contrib/tree/main/instrumentation
    require "opentelemetry-instrumentation-action_mailer" # rails
    require "opentelemetry-instrumentation-action_pack" # rails
    require "opentelemetry-instrumentation-action_view" # rails
    require "opentelemetry-instrumentation-active_job" # rails
    require "opentelemetry-instrumentation-active_record" # rails
    require "opentelemetry-instrumentation-active_storage" # rails
    require "opentelemetry-instrumentation-active_support" # rails
    require "opentelemetry-instrumentation-aws_sdk" # direct dependency
    require "opentelemetry-instrumentation-dalli" # memcached driver
    require "opentelemetry-instrumentation-excon" # used by fog
    require "opentelemetry-instrumentation-faraday" # indirect
    require "opentelemetry-instrumentation-grape" # direct
    require "opentelemetry-instrumentation-httpx" # direct dependency
    require "opentelemetry-instrumentation-net_http" # used by faraday
    require "opentelemetry-instrumentation-pg" # postgres driver
    require "opentelemetry-instrumentation-rack"
    require "opentelemetry-instrumentation-rails" # rails
    require "opentelemetry-instrumentation-rake"
    require "opentelemetry-instrumentation-redis"

    require "opentelemetry/semconv/incubating/deployment"
    require "opentelemetry/semconv/incubating/host"
    require "opentelemetry/semconv/incubating/service"

    # add log tags for log correlation
    if config.log_tags
      config.log_tags += [
        ->(*) { "trace_id=#{OpenTelemetry::Trace.current_span.context.hex_trace_id}" },
        ->(*) { "span_id=#{OpenTelemetry::Trace.current_span.context.hex_span_id}" }
      ]
    end

    OpenTelemetry::SDK.configure do |c|
      c.resource = OpenTelemetry::SDK::Resources::Resource.create(
        {
          OpenTelemetry::SemConv::Incubating::DEPLOYMENT::DEPLOYMENT_ENVIRONMENT => Rails.env,
          OpenTelemetry::SemConv::Incubating::HOST::HOST_NAME => Socket.gethostname,
          OpenTelemetry::SemConv::Incubating::SERVICE::SERVICE_INSTANCE_ID => SecureRandom.uuid,
          OpenTelemetry::SemConv::Incubating::SERVICE::SERVICE_NAME => OpenProject::OpenTelemetry.process_type,
          OpenTelemetry::SemConv::Incubating::SERVICE::SERVICE_NAMESPACE => "openproject",
          OpenTelemetry::SemConv::Incubating::SERVICE::SERVICE_VERSION => OpenProject::VERSION.to_s
        }.transform_values(&:to_s)
      )

      c.use_all(
        "OpenTelemetry::Instrumentation::PG" => {
          # SQL statements are included, but are obfuscated. If the query exceeds 2000 characters
          # by default, it will be completely omitted. We're hitting the limit quite often, so let's
          # increase it slightly so we get a bit more visibility.
          obfuscation_limit: 4000,

          # If available in PG::Result, include number of rows returned/affected.
          db_response_returned_rows: true,
          db_response_affected_rows: true
        }
      )
    end

    OpenProject::OpenTelemetry::ExconHashQuery.apply!

    # Extend the core log delegator
    handler = OpenProject::OpenTelemetry.method(:exception_handler)
    OpenProject::Logging::LogDelegator.register(:opentelemetry, handler)
  end
end
