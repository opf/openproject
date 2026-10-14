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
  let(:query) { nil }

  subject(:tree) { described_class.new(vc_test_controller.view_context, query:, hidden_menu_items:) }

  def url_helpers = Rails.application.routes.url_helpers

  def leaf_labels(nodes) = nodes.flat_map { it.children.empty? ? [it.label] : leaf_labels(it.children) }

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

    context "with a query" do
      let(:query) { "registration self" }

      it "keeps only matching settings regardless of word order and punctuation" do
        expect(leaf_labels(tree.nodes)).to eq ["Self-registration"]
      end
    end

    context "with a query matching a tab" do
      let(:query) { "passwords" }

      it "keeps all settings below it" do
        expect(leaf_labels(tree.nodes)).to include("Minimum length", "Enable password reset")
      end
    end

    context "with a query matching a tab and a setting" do
      let(:query) { "passwords minimum" }

      it "keeps only that setting" do
        expect(leaf_labels(tree.nodes)).to eq ["Minimum length"]
      end
    end

    context "with a query matching a description" do
      let(:query) { "comma separated" }

      it "keeps the described settings" do
        expect(leaf_labels(tree.nodes)).to include("Objects per page options")
      end
    end

    context "with a query matching nothing" do
      let(:query) { "xyzzy" }

      it "is empty" do
        expect(tree.nodes).to be_empty
      end
    end

    context "with entities" do
      shared_let(:bug) { create(:type, name: "Bug", position: 1) }
      shared_let(:feature) { create(:type, name: "Feature", position: 2) }

      it "lists the attributes of a kind, leading to the first entity" do
        node = find_node(tree.nodes, "Work packages", "Types", "Color")

        expect(node.href).to eq "#{url_helpers.edit_type_details_path(bug)}?highlight=type%5Bcolor_id%5D"
      end

      it "does not list the entities themselves" do
        expect(find_node(tree.nodes, "Work packages", "Types").children.map(&:label)).not_to include("Bug", "Feature")
      end

      context "with a query matching an entity and an attribute" do
        let(:query) { "feature color" }

        it "lists the entity with the matching attribute only" do
          node = find_node(tree.nodes, "Work packages", "Types", "Feature", "Color")

          expect(node.href).to eq "#{url_helpers.edit_type_details_path(feature)}?highlight=type%5Bcolor_id%5D"
          expect(leaf_labels(tree.nodes)).to eq ["Color"]
        end
      end

      context "with a query matching an entity only" do
        let(:query) { "feature" }

        it "lists all of its attributes" do
          expect(find_node(tree.nodes, "Work packages", "Types", "Feature").children.map(&:label))
            .to include("Name", "Color", "Is milestone")
        end
      end

      context "with more matching entities than listed" do
        let(:query) { "type" }

        before { (Settings::EntityKinds::MATCH_LIMIT + 1).times { create(:type, name: "Some type #{it}") } }

        it "lists only a limited number" do
          types = find_node(tree.nodes, "Work packages", "Types").children.select { it.label.start_with?("Some type") }

          expect(types.size).to eq Settings::EntityKinds::MATCH_LIMIT
        end
      end
    end

    context "with roles" do
      shared_let(:role) { create(:project_role, name: "Developer") }

      let(:query) { "developer edit work packages" }

      it "groups the permissions of a role" do
        node = find_node(tree.nodes, "Users and permissions", "Roles and permissions", "Developer", "Permissions",
                         "Edit work packages")

        expect(node.href)
          .to eq "#{url_helpers.edit_role_path(role)}?highlight=role%5Bpermissions%5D%5B%5D%3Dedit_work_packages"
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
