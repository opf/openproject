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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfiguration::GroupAttributeRowComponent, type: :component do
  include_context "with variant scope"

  let(:type) { create(:type) }
  let(:variant) { type.default_variant }
  let(:attribute) do
    { key: "assignee", is_cf: false, required_globally: false, required_for_variant: false, translation: "Assignee",
      field_format_label: "Built-in field" }
  end

  def editor_context(readonly: false, exclusions: nil)
    WorkPackageTypes::FormConfiguration::EditorContext.for_variant(variant, scope_project: nil).tap do |context|
      allow(context).to receive_messages(readonly?: readonly, exclusions:)
    end
  end

  it "renders the drag handle and actions menu in editable mode", :aggregate_failures do
    render_inline(described_class.new(attribute:, context: editor_context, index: 0, total_count: 2))

    expect(page).to have_test_selector("type-form-configuration-attribute-handle-assignee")
    expect(page).to have_test_selector("type-form-configuration-attribute-actions-assignee")
    expect(page).to have_text("Assignee")
  end

  it "omits the handle and actions menu when readonly", :aggregate_failures do
    render_inline(described_class.new(attribute:, context: editor_context(readonly: true), index: 0, total_count: 2))

    expect(page).to have_no_test_selector("type-form-configuration-attribute-handle-assignee")
    expect(page).to have_no_test_selector("type-form-configuration-attribute-actions-assignee")
    expect(page).to have_text("Assignee")
  end

  it "renders built-in attributes as secondary labels" do
    render_inline(described_class.new(attribute:, context: editor_context(readonly: true), index: 0, total_count: 2))

    expect(page).to have_css(".Label.Label--secondary", text: I18n.t("label_builtin"))
  end

  # The switch itself is covered by ExclusionToggleComponent; what matters here is that the row
  # hands it this attribute's key and label, and asks for it only in read-only mode.
  describe "the exclusion toggle" do
    def render_row(exclusions:, readonly: true)
      render_inline(described_class.new(attribute:, context: editor_context(readonly:, exclusions:), index: 0, total_count: 2))
    end

    it "is not rendered in editable mode" do
      render_row(exclusions: nil, readonly: false)

      expect(page).to have_no_test_selector("toggle-form-config-exclusion-assignee")
    end

    it "is not rendered when the type owns the configuration" do
      render_row(exclusions: nil)

      expect(page).to have_no_test_selector("toggle-form-config-exclusion-assignee")
    end

    it "is keyed on the attribute and labelled with its translation", :aggregate_failures do
      render_row(exclusions: WorkPackageTypes::ExclusionState.new(variant:, excluded: []))

      toggle = page.find("[data-test-selector='toggle-form-config-exclusion-assignee']")
      expect(toggle.find("button")["aria-label"]).to eq("Inherit Assignee")
    end
  end

  describe "custom field" do
    let(:attribute) do
      { key: "custom_field_5", is_cf: true, is_required: false, translation: "Alt description", field_format_label: "Text" }
    end

    it "shows a muted field format label" do
      render_inline(described_class.new(attribute:, context: editor_context(readonly: true), index: 0, total_count: 2))

      expect(page).to have_css(".color-fg-muted.text-small", text: attribute[:field_format_label])
    end
  end
end
