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
        { key: "assignee", is_cf: false, required_globally: false, required_for_variant: false, translation: "Assignee",
          field_format_label: "Built-in field" }
      ],
      query: nil
    }
  end

  it "renders handles and per-row drag data in editable mode", :aggregate_failures do
    render_inline(described_class.new(group:, variant:, ee_available: true, first: true, last: true))

    expect(page).to have_test_selector("type-form-configuration-group-handle-details")
    expect(page).to have_test_selector("type-form-configuration-attribute-handle-assignee")
  end

  it "renders the update-query URL for the group as data", :aggregate_failures do
    render_inline(described_class.new(group:, variant:, ee_available: true, first: true, last: true))

    expect(page).to have_element "data-group-key": "details" do |wrapper|
      expect(wrapper["data-update-query-url"]).to end_with("/form_configuration/group/update_query?key=details")
    end
  end

  context "with HTML-sensitive characters in the key" do
    let(:key) { 'b) > 10.000 "<Nutzende>"' }
    let(:group) { { key:, name: key, type: :attribute, attributes: [], query: nil } }

    it "escapes the key inside the data attributes", :aggregate_failures do
      render_inline(described_class.new(group:, variant:, ee_available: true, first: true, last: true))

      expect(page).to have_element "data-group-key": key do |wrapper|
        expect(wrapper["data-draggable-id"]).to eq(key)
        expect(wrapper["data-update-query-url"]).to end_with("?key=b%29+%3E+10.000+%22%3CNutzende%3E%22")
      end
    end
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
