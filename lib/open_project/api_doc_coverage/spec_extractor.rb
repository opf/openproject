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
    # Turns an assembled OpenAPI spec Hash into a list of Endpoints.
    class SpecExtractor
      HTTP_METHODS = %w[get post put patch delete].freeze

      def initialize(spec)
        @spec = spec
      end

      def endpoints
        (@spec["paths"] || {}).flat_map do |path, operations|
          operations.slice(*HTTP_METHODS).map do |method, operation|
            Endpoint.new(
              method: method.upcase,
              path:,
              module_name: PathNormalizer.module_name(path),
              params: params_for(operation)
            )
          end
        end
      end

      private

      def params_for(operation)
        parameter_params(operation) + body_params(operation)
      end

      def parameter_params(operation)
        Array(operation["parameters"]).map do |param|
          Param.new(name: param["name"], location: param["in"], required: !!param["required"])
        end
      end

      def body_params(operation)
        schema = request_body_schema(operation)
        return [] unless schema.is_a?(Hash) && schema["properties"].is_a?(Hash)

        required = Array(schema["required"])
        schema["properties"].keys.map do |name|
          Param.new(name:, location: "body", required: required.include?(name))
        end
      end

      def request_body_schema(operation)
        content = operation.dig("requestBody", "content")
        return nil unless content

        schema = content.values.first&.dig("schema")
        resolve_ref(schema)
      end

      def resolve_ref(node)
        return node unless node.is_a?(Hash) && node["$ref"].is_a?(String)

        path = node["$ref"].delete_prefix("#/").split("/")
        @spec.dig(*path)
      end
    end
  end
end
