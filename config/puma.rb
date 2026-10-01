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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma.
#
threads_min_count = OpenProject::Configuration.web_min_threads
threads_max_count = OpenProject::Configuration.web_max_threads
threads threads_min_count, [threads_min_count, threads_max_count].max

# Specifies the address on which Puma will listen on to receive requests; default is localhost.
set_default_host ENV.fetch("HOST") { "localhost" }

# Specifies the port that Puma will listen on to receive requests; default is 3000.
port ENV.fetch("PORT") { 3000 }.to_i

# Specifies the environment that Puma will run in.
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked webserver processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers OpenProject::Configuration.web_workers

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app! if ENV["RAILS_ENV"] == "production"

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart unless ENV["RAILS_ENV"] == "production"

plugin :appsignal if ENV["APPSIGNAL_ENABLED"] == "true"

if ENV["OPENPROJECT_PROMETHEUS_EXPORT"] == "true"
  activate_control_app
  plugin :yabeda
  plugin :yabeda_prometheus
end

# activate statsd plugin only if a host is configured explicitly
if OpenProject::Configuration.statsd_host.present?
  module ConfigurationViaOpenProject
    def initialize
      host = OpenProject::Configuration.statsd_host
      port = OpenProject::Configuration.statsd_port

      Rails.logger.debug { "Enabling puma statsd plugin (publish to udp://#{host}:#{port})" }

      @host = host
      @port = port
    end
  end

  StatsdConnector.prepend ConfigurationViaOpenProject

  plugin :statsd
end

metrics_enabled = OpenProject::Configuration.metrics["enabled"]

if metrics_enabled
  def start_metrics_server!
    require "open_project/metrics/metrics_app"

    Thread.new do
      require "webrick"

      port = OpenProject::Configuration.metrics["port"]
      # we silence the logs because lots of 'GET /metrics HTTP/1.1' logs are not particularly useful
      server = WEBrick::HTTPServer.new Port: port, BindAddress: "0.0.0.0", AccessLog: []

      Rails.logger.info "Starting metrics server on port #{port} under /metrics"

      server.mount "/", Rack::Handler::WEBrick, OpenProject::Metrics::MetricsApp.new
      server.start
    end
  end

  if OpenProject::Configuration.web["workers"] > 0
    before_fork do
      start_metrics_server!
    end
  else
    start_metrics_server!
  end
end

# Open app in default browser by pressing Ctrl+T
if Rails.env.development?
  siginfo_supported = begin
    Signal.trap("INFO", "IGNORE")
  rescue ArgumentError
    # Ignore unsupported signal `SIGINFO' on Linux
  end

  if siginfo_supported
    after_booted do
      Signal.trap("INFO") do
        system "open", Rails.application.root_url
      end
    end

    # Remove handling of INFO signal in forked workers
    on_worker_boot do
      Signal.trap("INFO", "IGNORE")
    end
  end
end
