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

module McpConfigurations
  class ServerForm < ApplicationForm
    include Redmine::I18n

    form do |f|
      f.check_box(
        name: :enabled,
        label: McpConfiguration.human_attribute_name(:enabled)
      )

      if server_enabled?
        f.html_content do
          render(McpConfigurations::ServerUrlComponent.new)
        end

        f.text_field(
          name: :title,
          label: McpConfiguration.human_attribute_name(:title),
          caption: I18n.t("admin.mcp_configurations.server_form.title_caption"),
          input_width: :large
        )

        f.text_area(
          name: :description,
          label: McpConfiguration.human_attribute_name(:description),
          caption: I18n.t("admin.mcp_configurations.server_form.description_caption"),
          input_width: :large,
          rows: 4
        )

        f.radio_button_group(
          name: :tool_response_format,
          label: I18n.t("admin.mcp_configurations.server_form.tool_response_format")
        ) do |radios|
          radios.radio_button(
            value: :full,
            checked: current_response_format?(:full),
            label: I18n.t("admin.mcp_configurations.server_form.tool_response_format_full_label"),
            caption: I18n.t("admin.mcp_configurations.server_form.tool_response_format_full_caption")
          )

          radios.radio_button(
            value: :structured_only,
            checked: current_response_format?(:structured_only),
            label: I18n.t("admin.mcp_configurations.server_form.tool_response_format_structured_only_label"),
            caption: I18n.t("admin.mcp_configurations.server_form.tool_response_format_structured_only_caption")
          )

          radios.radio_button(
            value: :content_only,
            checked: current_response_format?(:content_only),
            label: I18n.t("admin.mcp_configurations.server_form.tool_response_format_content_only_label"),
            caption: I18n.t("admin.mcp_configurations.server_form.tool_response_format_content_only_caption")
          )
        end
      end

      f.submit(
        name: :submit,
        label: I18n.t(:button_update),
        scheme: :secondary
      )
    end

    private

    def server_enabled?
      model.enabled?
    end

    def tool_response_format
      Setting.mcp_tool_response_format
    end

    def current_response_format?(format)
      format == tool_response_format
    end
  end
end
