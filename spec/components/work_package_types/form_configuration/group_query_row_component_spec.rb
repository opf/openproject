# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfiguration::GroupQueryRowComponent, type: :component do
  let(:group) { { key: "query-1", name: "Related", type: :query } }

  it "renders the edit-query action when EE and editable" do
    render_inline(described_class.new(group:, ee_available: true))

    expect(page).to have_test_selector("type-form-configuration-query-actions-query-1")
  end

  it "omits the actions menu when readonly", :aggregate_failures do
    render_inline(described_class.new(group:, ee_available: true, readonly: true))

    expect(page).to have_no_test_selector("type-form-configuration-query-actions-query-1")
    expect(page).to have_text("Related work packages table")
  end
end
