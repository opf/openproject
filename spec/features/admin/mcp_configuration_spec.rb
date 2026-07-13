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

require "spec_helper"

RSpec.describe "MCP configuration page", :js do
  shared_let(:admin) { create(:admin) }
  current_user { admin }

  before do
    # Using the regular seeder here, to have exact/realistic configurations (all tools, etc.)
    McpConfigurationSeeder.new(nil).seed!
  end

  context "when the enterprise feature is enabled", with_ee: %i[mcp_server] do
    context "when MCP server is enabled" do
      # rubocop:disable Rails/RedundantActiveRecordAllMethod
      let(:example_tool) { McpConfiguration.find_by(identifier: McpTools.all.first.qualified_name) }
      let(:example_resource) { McpConfiguration.find_by(identifier: McpResources.all.first.qualified_name) }
      # rubocop:enable Rails/RedundantActiveRecordAllMethod

      before do
        McpConfiguration.server_config.update!(enabled: true)
      end

      it "allows changing server configuration" do
        visit mcp_configurations_path

        within_test_selector("mcp-configuration--server-config-form") do
          expect(page).to have_field "Title", with: McpConfiguration.server_config.title
          expect(page).to have_field "Description", with: McpConfiguration.server_config.description

          fill_in "Title", with: "My custom server title"
          fill_in "Description", with: "My custom server description is great."
          click_button "Update"

          wait_for_network_idle

          expect(McpConfiguration.server_config.title).to eq("My custom server title")
          expect(McpConfiguration.server_config.description).to eq("My custom server description is great.")
          expect(page).to have_field "Title", with: McpConfiguration.server_config.title
          expect(page).to have_field "Description", with: McpConfiguration.server_config.description
        end

        # Page is expected to allow configuration of all tools and resources
        expect(page).to have_test_selector("mcp-configuration--config-row-name", count: McpTools.all.size + McpResources.all.size)

        within_test_selector("mcp-configuration--server-config-form") do
          uncheck "Enabled"
          click_button "Update"

          wait_for_network_idle

          expect(page).to have_field "Enabled"
          expect(page).to have_no_field "Title"
          expect(page).to have_no_field "Description"
        end

        expect(page).to have_no_test_selector("mcp-configuration--config-row-name")
      end

      it "allows changing tool and resource configuration" do
        visit mcp_configurations_path

        # only changing this to submit another form afterwards and expect no change to this tool
        page.find_test_selector("mcp-configuration--title-input-#{example_tool.identifier}").set("My new tool title")
        page.find_test_selector("mcp-configuration--title-input-#{example_resource.identifier}").set("My new resource title")
        click_button "Update resources"

        wait_for_network_idle

        expect { example_tool.reload }.not_to change(example_tool, :title)
        expect { example_resource.reload }.to change(example_resource, :title).to("My new resource title")

        # only changing this to submit another form afterwards and expect no change to this tool
        page.find_test_selector("mcp-configuration--title-input-#{example_resource.identifier}").set("My other resource title")
        page.find_test_selector("mcp-configuration--title-input-#{example_tool.identifier}").set("My new tool title")
        click_button "Update tools"

        wait_for_network_idle

        expect { example_resource.reload }.not_to change(example_resource, :title)
        expect { example_tool.reload }.to change(example_tool, :title).to("My new tool title")
      end
    end

    context "when MCP server is disabled" do
      before do
        McpConfiguration.server_config.update!(enabled: false)
      end

      it "does not show anything, but allows enabling the server" do
        visit mcp_configurations_path

        expect(page).to have_no_test_selector("mcp-configuration--config-row-name")

        within_test_selector("mcp-configuration--server-config-form") do
          check "Enabled"
          click_button "Update"

          wait_for_network_idle

          expect(page).to have_field "Enabled"
          expect(page).to have_field "Title"
          expect(page).to have_field "Description"
        end

        # Page is expected to allow configuration of all tools and resources after enabling again
        expect(page).to have_test_selector("mcp-configuration--config-row-name", count: McpTools.all.size + McpResources.all.size)
      end
    end
  end

  context "when the enterprise feature is disabled" do
    it "hides the entire form, but shows an enterprise banner" do
      visit mcp_configurations_path

      expect(page).to have_enterprise_banner(:professional)

      expect(page).to have_no_test_selector("mcp-configuration--server-config-form")
      expect(page).to have_no_test_selector("mcp-configuration--config-row-name")
    end
  end
end
