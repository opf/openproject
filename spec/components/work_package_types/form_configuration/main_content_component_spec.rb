# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfiguration::MainContentComponent, type: :component do
  let(:variant) { create(:type).default_variant }

  it "renders Reset and Add actions in editable EE mode", :aggregate_failures do
    render_inline(described_class.new(variant:, group_components: [], ee_available: true))

    expect(page).to have_test_selector("type-form-configuration-reset-button")
    expect(page).to have_test_selector("type-form-configuration-add-button")
  end

  it "omits Reset, Add, and drag targets when readonly", :aggregate_failures do
    render_inline(described_class.new(variant:, group_components: [], ee_available: true, readonly: true))

    expect(page).to have_no_test_selector("type-form-configuration-reset-button")
    expect(page).to have_no_test_selector("type-form-configuration-add-button")
    expect(page).to have_no_css("[data-admin--type-form-configuration--drag-and-drop-target]")
    expect(page).to have_test_selector("type-form-configuration-groups-container")
  end
end
