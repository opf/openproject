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

  describe "the exclusion toggle" do
    let(:type) { create(:type) }
    let(:variant) { type.default_variant }
    let(:exclusions) do
      WorkPackageTypes::ExclusionState.new(
        variant:, own: [], effective: []
      )
    end

    it "is keyed on the query and labelled with the section name", :aggregate_failures do
      render_inline(described_class.new(group: group.merge(element_key: "query_7"),
                                        ee_available: false, readonly: true, exclusions:))

      toggle = page.find("[data-test-selector='toggle-form-config-exclusion-query_7']")
      expect(toggle.find("button")["aria-label"]).to eq("Inherit section Related")
    end

    it "is omitted for a group whose query was deleted" do
      render_inline(described_class.new(group: group.merge(element_key: nil),
                                        ee_available: true, readonly: true, exclusions:))

      expect(page).to have_no_css("toggle-switch")
    end
  end
end
