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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module McpTools
  # A tool that effectively only serves a result that could've been obtained by fetching a resource
  # Useful for clients that don't support resources, or ignore them, even if they could support them.
  class ResourceProxyTool < Base
    class << self
      def resource(resource = nil)
        @resource = resource if resource.present?

        @resource
      end

      def resource_schema(schema_definition)
        output_schema(JsonSchemaLoader.new.load(schema_definition))
      end

      def resource_annotations
        annotations read_only: true, idempotent: true, destructive: false
      end
    end

    private

    def call
      McpResources.read_resource_content(self.class.resource.uri, resources_considered: McpResources.all)
    end

    def format_content(result)
      [{ type: "resource", resource: McpResources.format_json_resource(self.class.resource.uri, result) }]
    end
  end
end
