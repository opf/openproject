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

require_relative "endpoint"
require_relative "path_normalizer"

module OpenProject
  module ApiDocCoverage
    # Enumerates the real Grape routes of the APIv3 into Endpoints.
    class RouteExtractor
      NOISE_PARAMS = %w[format version].freeze
      HTTP_METHODS = %w[GET POST PUT PATCH DELETE HEAD OPTIONS].freeze

      def initialize(grape_api = API::Root)
        @grape_api = grape_api
      end

      def endpoints
        @grape_api.routes.select { |route| documentable?(route) }.map { |route| build_endpoint(route) }
      end

      private

      def documentable?(route)
        v3_route?(route) && http_method?(route)
      end

      # API::Root also hosts non-v3 mounts (e.g. the BIM module's "v1" BCF XML
      # API), which use :version as an ordinary path segment rather than as the
      # path-versioning prefix. Only routes actually versioned via the
      # /:version prefix belong to the documented APIv3 surface.
      def v3_route?(route)
        PathNormalizer::VERSION_PREFIX.match?(route.path)
      end

      # Grape mounts a catch-all fallback route with the wildcard method "*"
      # (path "?*path"); it is not a documentable endpoint.
      def http_method?(route)
        HTTP_METHODS.include?(route.request_method.to_s.upcase)
      end

      def build_endpoint(route)
        path = PathNormalizer.canonical_path(route.path)
        Endpoint.new(
          method: route.request_method.to_s.upcase,
          path:,
          module_name: PathNormalizer.module_name(path),
          params: build_params(route, path)
        )
      end

      def build_params(route, canonical_path)
        path_names = canonical_path.scan(/\{(\w+)\}/).flatten
        route.params.each_key.reject { |name| NOISE_PARAMS.include?(name.to_s) }.map do |name|
          build_param(name, route.params[name], path_names)
        end
      end

      def build_param(name, meta, path_names)
        Param.new(
          name: name.to_s,
          location: path_names.include?(name.to_s) ? "path" : nil,
          required: meta.is_a?(Hash) ? !!meta[:required] : false
        )
      end
    end
  end
end
