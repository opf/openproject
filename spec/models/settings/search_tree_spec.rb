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

require "spec_helper"

RSpec.describe Settings::SearchTree do
  include ViewComponent::TestHelpers

  shared_let(:admin) { create(:admin) }

  let(:hidden_menu_items) { [] }

  subject(:tree) { described_class.new(vc_test_controller.view_context, hidden_menu_items:) }

  def find_node(nodes, *labels)
    labels.reduce(nil) do |node, label|
      level = node ? node.children : nodes
      level.find { it.label == label } || raise("No node #{label.inspect} among #{level.map(&:label).inspect}")
    end
  end

  context "as an admin" do
    current_user { admin }

    it "places settings below their admin menu items" do
      node = find_node(tree.nodes, "System settings", "General", "Application title")

      expect(node.href).to eq "/admin/settings/general?highlight=app_title"
      expect(node.children).to be_empty
    end

    it "places settings of tabbed pages below the tab" do
      node = find_node(tree.nodes, "Authentication", "Login and registration", "Passwords", "Minimum length")

      expect(node.href).to eq "/admin/settings/authentication?highlight=password_min_length&tab=passwords"
    end

    it "links menu items and tabs" do
      expect(find_node(tree.nodes, "System settings", "External links").href).to eq "/admin/settings/external_links"
      expect(find_node(tree.nodes, "Authentication", "Login and registration", "Passwords").href)
        .to eq "/admin/settings/authentication?tab=passwords"
    end

    it "uses the plain text caption as description" do
      node = find_node(tree.nodes, "System settings", "General", "Host name")

      expect(node.description).to eq "Example: test.host"
    end

    it "omits menu items without registered settings" do
      expect(tree.nodes.map(&:label)).not_to include("Overview", "Information")
    end

    it "omits the multiple versions conversion once it is done" do
      expect(find_node(tree.nodes, "Work packages").children.map(&:label)).not_to include("Versions and categories")
    end

    it "describes real-time collaboration independently of its state" do
      node = find_node(tree.nodes, "Documents", "Real-time collaboration", "Real-time collaboration")

      expect(node.description)
        .to eq "Allows multiple users to edit a document at the same time. Requires a working Hocuspocus server."
    end

    context "with the multiple versions conversion pending", with_settings: { work_package_multiple_versions: false } do
      it "lists the conversion below its menu item" do
        node = find_node(tree.nodes, "Work packages", "Versions and categories", "Multiple target versions")

        expect(node.href).to eq "/admin/settings/versions_and_categories?highlight=work_package_multiple_versions"
      end
    end

    context "with a hidden menu item" do
      let(:hidden_menu_items) { ["settings_general"] }

      it "omits its settings" do
        expect(find_node(tree.nodes, "System settings").children.map(&:label)).not_to include("General")
      end
    end
  end

  context "as a regular user" do
    current_user { create(:user) }

    it "is empty" do
      expect(tree.nodes).to be_empty
    end
  end
end
