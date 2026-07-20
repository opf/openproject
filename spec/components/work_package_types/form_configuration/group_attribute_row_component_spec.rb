# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfiguration::GroupAttributeRowComponent, type: :component do
  let(:type) { create(:type) }
  let(:attribute) do
    { key: "assignee", is_cf: false, is_required: false, translation: "Assignee", field_format_label: "Built-in field" }
  end

  it "renders the drag handle and actions menu in editable mode", :aggregate_failures do
    render_inline(described_class.new(attribute:, type:, index: 0, total_count: 2))

    expect(page).to have_test_selector("type-form-configuration-attribute-handle-assignee")
    expect(page).to have_test_selector("type-form-configuration-attribute-actions-assignee")
    expect(page).to have_text("Assignee")
  end

  it "omits the handle and actions menu when readonly", :aggregate_failures do
    render_inline(described_class.new(attribute:, type:, index: 0, total_count: 2, readonly: true))

    expect(page).to have_no_test_selector("type-form-configuration-attribute-handle-assignee")
    expect(page).to have_no_test_selector("type-form-configuration-attribute-actions-assignee")
    expect(page).to have_text("Assignee")
  end
end
