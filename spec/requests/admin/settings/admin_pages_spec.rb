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

require "spec_helper"

RSpec.describe "Settings on admin pages",
               :settings_reset,
               type: :rails_request,
               with_ee: %i[sso_auth_providers mcp_server scim_api ldap_groups customize_life_cycle
                           custom_actions placeholder_users xwiki_integration define_custom_style],
               with_flag: { llm_connection: true, ai_text_transform_actions: true, wiki_enhancements: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:internal_wiki_provider) { create(:internal_wiki_provider) }

  before { login_as(admin) }

  let(:view_context) { ApplicationController.new.tap { it.request = ActionDispatch::TestRequest.create }.view_context }
  let(:menu_item_names) { Settings::Pages.admin_menu.to_set { it.name.to_s } }

  def menu_item_nodes(nodes)
    nodes.flat_map do |node|
      own = menu_item_names.include?(node.key) ? [node] : []
      [*own, *menu_item_nodes(node.children)]
    end
  end

  # Menu items with children link to the page of one of them.
  def registered_names(menu_item)
    menu_items = Settings::Pages.admin_menu.find { it.name.to_s == menu_item }.map(&:name)
    entries = Settings::Pages.all.select { menu_items.include?(it.menu_item) }.flat_map(&:entries)
    entries.flat_map { [it.highlight, it.field || "settings[#{it.name}]"] }.to_set
  end

  def rendered_names
    fields = response.parsed_body.css("[name^='settings[']")
      .map { it["name"][/\Asettings\[([^\]]+)\]/, 1] }
      .select { Settings::Definition.exists?(it) }
      .map { "settings[#{it}]" }
    markers = response.parsed_body.css("[data-setting-name]").map { it["data-setting-name"] }
    (fields + markers).uniq
  end

  it "registers every setting rendered on the page of an admin menu item", :aggregate_failures do
    nodes = menu_item_nodes(User.execute_as(admin) { Settings::SearchTree.new(view_context).nodes })

    expect(nodes).not_to be_empty

    nodes.each do |node|
      get node.href

      next if response.redirect?

      expect(response).to have_http_status(:ok), "for #{node.href}"

      unregistered = rendered_names - registered_names(node.key).to_a
      expect(unregistered).to be_empty, "unregistered settings on #{node.href}: #{unregistered.join(', ')}"
    end
  end
end
