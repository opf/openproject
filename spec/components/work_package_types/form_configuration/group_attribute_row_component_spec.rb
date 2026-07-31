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

  describe "the exclusion toggle" do
    subject(:toggle) { page.find("[data-test-selector='toggle-form-config-exclusion-assignee']") }

    def render_row(exclusions:, readonly: true)
      render_inline(described_class.new(attribute:, type:, index: 0, total_count: 2, readonly:, exclusions:))
    end

    def exclusion_state(own:, effective:)
      WorkPackageTypes::FormConfigurationComponent::ExclusionState.new(type:, own:, effective:)
    end

    it "is not rendered in editable mode" do
      render_row(exclusions: nil, readonly: false)

      expect(page).to have_no_test_selector("toggle-form-config-exclusion-assignee")
    end

    it "is not rendered when the type owns the configuration" do
      render_row(exclusions: nil)

      expect(page).to have_no_test_selector("toggle-form-config-exclusion-assignee")
    end

    it "is on and posts to the toggle endpoint when the element is not excluded", :aggregate_failures do
      render_row(exclusions: exclusion_state(own: [], effective: []))

      expect(toggle.find("button")["aria-pressed"]).to eq("true")
      expect(toggle.find("button")["aria-label"]).to eq("Inherit Assignee")
      expect(toggle["src"]).to eq(
        "/types/#{type.id}/exclusions/form_configuration/toggle?element=assignee"
      )
    end

    # Rows an ancestor excludes never reach this component: FormConfigurationComponent leaves them
    # out, so the switch here is always writable.
    it "is off and still writable when this type excludes the element itself", :aggregate_failures do
      render_row(exclusions: exclusion_state(own: %w[assignee], effective: %w[assignee]))

      expect(toggle.find("button")["aria-pressed"]).to eq("false")
      expect(toggle["src"]).to be_present
      expect(toggle["class"]).not_to include("ToggleSwitch--disabled")
    end
  end
end
