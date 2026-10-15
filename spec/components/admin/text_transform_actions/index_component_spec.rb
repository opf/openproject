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

require "rails_helper"

RSpec.describe Admin::TextTransformActions::IndexComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:type_a) { create(:type) }
  shared_let(:type_b) { create(:type) }

  subject(:rendered_component) do
    with_request_url "/admin/text_transform_actions" do
      render_inline(described_class.new(text_transform_actions:))
    end
  end

  context "with actions", with_settings: { ai_text_transform_actions_enabled: true } do
    shared_let(:action_a) { create(:ai_text_transform_action, label: "Fix grammar", active: true) }
    shared_let(:action_b) do
      create(:ai_text_transform_action, label: "Translate", active: false,
                                        usage_scope: "specific_work_package_types", types: [type_a, type_b])
    end

    let(:text_transform_actions) { [action_a, action_b] }

    it_behaves_like "rendering Box", row_count: 2
    it_behaves_like "rendering Border Box List heading", text: "Actions"

    it "wires the wrapper as the sortable-lists root with the drop URL template and no optimistic flag" do
      rendered_component

      root = page.find("[data-controller='sortable-lists']", visible: :all)

      expect(root["data-sortable-lists-move-url-template-value"]).to include("/admin/text_transform_actions/{id}/drop")
      expect(root["data-sortable-lists-optimistic-value"]).to be_nil
    end

    it "wires the root's outlet selectors so they actually resolve to the rendered list/items" do
      rendered_component

      root = page.find("[data-controller='sortable-lists']", visible: :all)
      list_outlet_selector = root["data-sortable-lists-sortable-lists--list-outlet"]
      item_outlet_selector = root["data-sortable-lists-sortable-lists--item-outlet"]

      expect(list_outlet_selector).to be_present
      expect(item_outlet_selector).to be_present
      expect(page).to have_css(list_outlet_selector)
      expect(page).to have_css(item_outlet_selector)
    end

    it "wires the border box as a sortable-lists list of type text_transform_action without a list id" do
      rendered_component

      expect(page).to have_css(
        "[data-controller~='sortable-lists--list']" \
        "[data-sortable-lists--list-type-value='text_transform_action']" \
        "[data-sortable-lists--list-accepted-type-value='text_transform_action']" \
        ":not([data-sortable-lists--list-id-value])"
      )
    end

    it "wires each row as a sortable-lists item with a drag handle and client-side move items" do
      rendered_component

      [action_a, action_b].each do |action|
        row = page.find(
          "[data-controller~='sortable-lists--item']" \
          "[data-sortable-lists--item-id-value='#{action.id}']" \
          "[data-sortable-lists--item-type-value='text_transform_action']" \
          "[data-sortable-lists--item-label-value='#{action.label}']"
        )

        expect(row).to have_css("[data-sortable-lists--item-target~='handle']")
        expect(row).to have_css("[data-sortable-lists--item-target~='moveItem']", count: 4, visible: :all)
      end
    end

    it "renders the scope, the active state and the edit link per row" do
      rendered_component

      row_a = page.find("[data-test-selector='text-transform-action-row-#{action_a.id}']")
      expect(row_a).to have_link("Fix grammar", href: edit_admin_text_transform_action_path(action_a))
      expect(row_a).to have_css("[data-test-selector='text-transform-action-scope']", text: "Everywhere")
      expect(row_a).to have_css("[data-test-selector='toggle-text-transform-action-#{action_a.id}'] [aria-pressed='true']")

      row_b = page.find("[data-test-selector='text-transform-action-row-#{action_b.id}']")
      expect(row_b).to have_css("[data-test-selector='text-transform-action-scope']", text: "2 work package types")
      expect(row_b).to have_css("[data-test-selector='toggle-text-transform-action-#{action_b.id}'] [aria-pressed='false']")
    end

    it "renders the enable all and disable all header actions as turbo stream requests" do
      rendered_component

      expect(page).to have_css(
        "a[href='#{enable_all_admin_text_transform_actions_path}'][data-turbo-method='put'][data-turbo-stream='true']",
        text: "Enable all"
      )
      expect(page).to have_css(
        "a[href='#{disable_all_admin_text_transform_actions_path}'][data-turbo-method='put'][data-turbo-stream='true']",
        text: "Disable all"
      )
    end

    it "has no generic-drag-and-drop remnants" do
      rendered_component

      expect(page.native.to_html).not_to match(/generic-drag-and-drop|dragula/)
    end

    it "renders no disabled warning" do
      rendered_component

      expect(page).to have_no_css("[data-test-selector='text-transform-actions-disabled-banner']")
    end
  end

  context "with actions while the assistant setting is disabled" do
    shared_let(:action) { create(:ai_text_transform_action, label: "Fix grammar", active: true) }

    let(:text_transform_actions) { [action] }

    it "renders the disabled warning banner" do
      rendered_component

      expect(page).to have_css(
        "[data-test-selector='text-transform-actions-disabled-banner']",
        text: "Text transform actions are disabled. The following actions will not be available anywhere."
      )
    end

    it "disables the row toggles and drops their mutation wiring" do
      rendered_component

      toggle = page.find("[data-test-selector='toggle-text-transform-action-#{action.id}']")
      expect(toggle).to have_css("button[disabled]")
      expect(toggle["src"]).to be_nil
    end

    it "disables the enable all and disable all header actions" do
      rendered_component

      expect(page).to have_css("button[disabled][data-test-selector='enable-all-text-transform-actions']")
      expect(page).to have_css("button[disabled][data-test-selector='disable-all-text-transform-actions']")
      expect(page).to have_no_css("a[href='#{enable_all_admin_text_transform_actions_path}']")
    end
  end

  context "without actions" do
    let(:text_transform_actions) { [] }

    it_behaves_like "rendering an empty Border Box List",
                    heading: I18n.t("admin.text_transform_actions.index_component.blank_slate.title"),
                    icon: :sparkle
  end
end
