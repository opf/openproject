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

module Admin
  class McpConfigurationsController < ::ApplicationController
    include OpTurbo::ComponentStream

    before_action :require_admin

    menu_item :mcp_configurations

    layout "admin"

    def index
      @server_config = McpConfiguration.server_config
      @tool_configs = McpConfiguration.where(identifier: McpTools.tools_by_name.keys).order(identifier: :asc)

      @resource_configs = McpConfiguration.where(identifier: McpResources.resources_by_name.keys).order(identifier: :asc)
    end

    def update
      config = McpConfiguration.find(params[:id])
      if config.update(mcp_config_params)
        update_tool_response_format
        flash[:notice] = t(".success")
      else
        flash[:error] = t(".failure")
      end

      redirect_to action: :index
    end

    def multi_update
      updates = params[:mcp_configurations]
      updates.transform_values! { |hash| hash.permit(:title, :description, :enabled) }

      updates.each do |identifier, attributes|
        McpConfiguration.find_by!(identifier:).update!(attributes)
      end

      flash[:notice] = t(".success")
      redirect_to action: :index
    end

    private

    def mcp_config_params
      params.expect(mcp_configuration: %i[enabled title description])
    end

    def update_tool_response_format
      return if tool_response_format_param.nil?
      return unless McpTools::Base::RESPONSE_FORMATS.include?(tool_response_format_param.to_sym)

      Setting.mcp_tool_response_format = tool_response_format_param
    end

    def tool_response_format_param
      params.dig(:mcp_configuration, :tool_response_format)
    end
  end
end
