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

module OpenProject
  module ApiDocCoverage
    class Differ
      Diff = Data.define(:undocumented_routes, :undocumented_params, :orphaned_paths) do
        def by_module
          modules = collect_module_names
          modules.uniq.index_with { |mod| group_for(mod) }
        end

        private

        def collect_module_names
          modules = (undocumented_routes + orphaned_paths).map(&:module_name)
          modules += undocumented_params.map { |h| h[:endpoint].module_name }
          modules
        end

        def group_for(mod)
          {
            undocumented_routes: undocumented_routes.select { |e| e.module_name == mod },
            undocumented_params: undocumented_params.select { |h| h[:endpoint].module_name == mod },
            orphaned_paths: orphaned_paths.select { |e| e.module_name == mod }
          }
        end
      end

      def initialize(routes:, specs:)
        @routes = routes
        @specs = specs
      end

      def diff
        Diff.new(
          undocumented_routes: undocumented_routes,
          undocumented_params: undocumented_params,
          orphaned_paths: orphaned_paths
        )
      end

      private

      def key(endpoint) = [endpoint.method, endpoint.path]

      def spec_by_key = @spec_by_key ||= @specs.index_by { |e| key(e) }
      def route_keys = @route_keys ||= @routes.to_set { |e| key(e) }

      def undocumented_routes
        @routes.reject { |e| spec_by_key.key?(key(e)) }
      end

      def orphaned_paths
        @specs.reject { |e| route_keys.include?(key(e)) }
      end

      def undocumented_params
        @routes.filter_map do |route|
          spec = spec_by_key[key(route)]
          next unless spec

          missing = param_names(route, exclude_path: true) - param_names(spec, exclude_path: false)
          next if missing.empty?

          { endpoint: route, param_names: missing }
        end
      end

      def param_names(endpoint, exclude_path:)
        params = exclude_path ? endpoint.params.reject { |p| p.location == "path" } : endpoint.params
        params.map(&:name)
      end
    end
  end
end
