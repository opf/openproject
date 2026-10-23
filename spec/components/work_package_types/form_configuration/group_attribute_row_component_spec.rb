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
  include_context "with a form configuration editor context"

  let(:attribute) do
    { id: 1, key: "assignee", is_cf: false, required_globally: false, required_for_variant: false,
      translation: "Assignee", field_format_label: "Built-in" }
  end

  def render_row(total_count: 2, row: attribute)
    render_inline(described_class.new(attribute: row, context: editor_context, total_count:))
  end

  it "renders the drag handle and actions menu in editable mode", :aggregate_failures do
    render_row

    expect(page).to have_test_selector("type-form-configuration-attribute-handle-assignee")
    expect(page).to have_test_selector("type-form-configuration-attribute-actions-assignee")
    expect(page).to have_text("Assignee")
  end

  context "when read-only" do
    let(:readonly) { true }

    it "omits the handle and actions menu", :aggregate_failures do
      render_row

      expect(page).to have_no_test_selector("type-form-configuration-attribute-handle-assignee")
      expect(page).to have_no_test_selector("type-form-configuration-attribute-actions-assignee")
      expect(page).to have_text("Assignee")
    end

    it "renders no type for built-in attributes" do
      render_row

      expect(page).to have_no_text(I18n.t("label_builtin"))
    end
  end

  describe "custom field" do
    let(:attribute) do
      { id: 2, key: "custom_field_5", is_cf: true, is_required: false, translation: "Alt description",
        field_format_label: "Text" }
    end

    it "offers no required toggle on the form's own page" do
      render_row

      expect(page).to have_no_test_selector("type-form-configuration-toggle-required-custom_field_5", visible: :all)
    end

    context "when read-only" do
      let(:readonly) { true }

      it "shows a muted field format label and offers the required toggle", :aggregate_failures do
        render_row

        expect(page).to have_css(".color-fg-muted.text-small", text: attribute[:field_format_label])
        expect(page).to have_test_selector("type-form-configuration-toggle-required-custom_field_5", visible: :all)
      end
    end
  end

  # The switch itself is covered by ExclusionToggleComponent; what matters here is that the row
  # hands it this attribute's key and label, and asks for it only in read-only mode.
  describe "the exclusion toggle" do
    it "is not rendered in editable mode" do
      render_row

      expect(page).to have_no_test_selector("toggle-form-config-exclusion-assignee")
    end

    context "when read-only" do
      let(:readonly) { true }

      it "is keyed on the attribute and labelled with its translation for any variant", :aggregate_failures do
        render_row

        toggle = page.find("[data-test-selector='toggle-form-config-exclusion-assignee'] > button")
        expect(toggle["aria-label"]).to eq("Inherit Assignee")
        expect(toggle["aria-pressed"]).to eq("true")
      end
    end
  end

  it_behaves_like "offers the shared move items" do
    let(:rendered_component) { render_row(total_count: 3) }
  end

  it_behaves_like "offers no move items" do
    let(:rendered_component) { render_row(total_count: 1) }
  end

  it "offers neither handle nor move items for an attribute without a record", :aggregate_failures do
    render_row(total_count: 3, row: attribute.except(:id))

    expect(page).to have_no_test_selector("type-form-configuration-attribute-handle-assignee")
    expect(page).to have_no_css("[data-sortable-lists--item-target='moveItem']", visible: :all)
    expect(page).to have_test_selector("type-form-configuration-delete-attribute-assignee", visible: :all)
  end
end
