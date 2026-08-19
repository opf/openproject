# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfiguration::GroupComponent, type: :component do
  let(:variant) { create(:type).default_variant }
  let(:group) do
    {
      key: "details",
      name: "Details",
      type: :attribute,
      attributes: [
        { key: "assignee", is_cf: false, is_required: false, translation: "Assignee", field_format_label: "Built-in field" }
      ],
      query: nil
    }
  end

  it "renders handles and per-row drag data in editable mode", :aggregate_failures do
    render_inline(described_class.new(group:, variant:, ee_available: true, first: true, last: true))

    expect(page).to have_test_selector("type-form-configuration-group-handle-details")
    expect(page).to have_test_selector("type-form-configuration-attribute-handle-assignee")
  end

  it "renders no handles, menus, or drag data when readonly", :aggregate_failures do
    render_inline(described_class.new(group:, variant:, ee_available: true, first: true, last: true, readonly: true))

    expect(page).to have_no_test_selector("type-form-configuration-group-handle-details")
    expect(page).to have_no_test_selector("type-form-configuration-attribute-handle-assignee")
    expect(page).to have_no_test_selector("type-form-configuration-attribute-actions-assignee")
    expect(page).to have_no_css("[data-draggable-id]")
    expect(page).to have_text("Details")
    expect(page).to have_text("Assignee")
  end

  context "with an empty group" do
    let(:group) { { key: "details", name: "Details", type: :attribute, attributes: [], query: nil } }

    it "shows the drag hint in editable mode" do
      render_inline(described_class.new(group:, variant:, ee_available: true, first: true, last: true))

      expect(page).to have_text("Drag attributes here")
    end

    it "omits the drag hint when readonly", :aggregate_failures do
      render_inline(described_class.new(group:, variant:, ee_available: true, first: true, last: true, readonly: true))

      expect(page).to have_no_text("Drag attributes here")
      expect(page).to have_text("Details")
    end
  end
end
