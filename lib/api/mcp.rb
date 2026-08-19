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

module API
  class Mcp < ::API::RootAPI
    include ::API::AppsignalAPI

    default_format :json

    error_representer ::API::Mcp::ErrorRepresenter, :json
    authentication_scope OpenProject::Authentication::Scope::MCP_SCOPE

    helpers do
      def server_config
        @server_config ||= McpConfiguration.server_config
      end
    end

    post "/" do
      if !EnterpriseToken.allows_to?(:mcp_server) || !server_config.enabled?
        status 404
        return "MCP server is not available."
      end

      server = MCP::Server.new(
        name: "openproject_mcp",
        title: server_config.title,
        # description: server_config.description, # not yet supported by mcp gem
        version: "1.0.0",
        tools: McpTools.enabled.map(&:tool),
        resources: McpResources.enabled_resources.map(&:resource),
        resource_templates: McpResources.enabled_resource_templates.map(&:resource_template),
        server_context: { current_user: User.current }
      )

      server.resources_read_handler { |params| McpResources.read_resource(params[:uri]) }

      status 200

      response = server.handle_json(request.body.read)

      # HACK: Grape is JSON-serializing whatever we return here, but handle_json already returns serialized JSON
      response && JSON.parse(response)
    end
  end
end
