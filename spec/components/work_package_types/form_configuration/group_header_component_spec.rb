# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfiguration::GroupHeaderComponent, type: :component do
  let(:variant) { create(:type).default_variant }
  let(:group) { { key: "details", name: "Details", type: :attribute } }

  def render_header(readonly:)
    render_inline(described_class.new(group:, variant:, ee_available: true, first: true, last: true,
                                      edit_mode: false, readonly:))
  end

  it "renders the drag handle and actions menu in editable mode", :aggregate_failures do
    render_header(readonly: false)

    expect(page).to have_test_selector("type-form-configuration-group-handle-details")
    expect(page).to have_test_selector("type-form-configuration-group-actions-details")
    expect(page).to have_text("Details")
  end

  it "omits the handle and actions menu when readonly", :aggregate_failures do
    render_header(readonly: true)

    expect(page).to have_no_test_selector("type-form-configuration-group-handle-details")
    expect(page).to have_no_test_selector("type-form-configuration-group-actions-details")
    expect(page).to have_text("Details")
  end
end
