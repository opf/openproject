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

# The OpenTelemetry grape instrumentation reads the endpoint's owner, HTTP method
# and path from +Grape::Endpoint#options+, and the route's version and prefix from
# +Grape::Router::Route#options+. Grape 4 promoted all of them to keyword arguments
# and readers, so upstream's `[prefix, version] + namespace.split('/') +
# endpoint.options[:path]` raises a TypeError on every instrumented request.
# Remove once the instrumentation reads the grape 4 accessors.
module OpenProject::Patches::OtelGrapeEventHandler
  private

  # +Grape::Endpoint#config+ is protected; only +#api+ is delegated publicly.
  def endpoint_config(endpoint)
    endpoint.send(:config)
  end

  def request_method(endpoint)
    endpoint_config(endpoint).http_methods.first
  end

  def code_namespace(endpoint)
    owner = endpoint.api
    return unless owner

    base = owner.instance_variable_get(:@base)
    [owner.name, base&.to_s, owner.to_s].find(&:present?)
  end

  def path(endpoint) # rubocop:disable Metrics/AbcSize
    route = endpoint.routes&.first
    return "" unless route

    parts = [route.prefix&.to_s, route.version&.to_s] + route.namespace.split("/") + endpoint_config(endpoint).path
    parts.reject { |p| p.blank? || p.eql?("/") }.join("/").prepend("/")
  end
end

if defined?(OpenTelemetry::Instrumentation::Grape::EventHandler)
  OpenProject::Patches.patch_gem_version "opentelemetry-instrumentation-grape", "0.7.1" do
    OpenTelemetry::Instrumentation::Grape::EventHandler
      .singleton_class
      .prepend OpenProject::Patches::OtelGrapeEventHandler
  end
end
