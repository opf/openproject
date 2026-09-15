# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfiguration::GroupAttributeRowComponent, type: :component do
  let(:type) { create(:type) }
  let(:variant) { type.default_variant }
  let(:attribute) do
    { key: "assignee", is_cf: false, required_globally: false, required_for_variant: false, translation: "Assignee",
      field_format_label: "Built-in field" }
  end

  it "renders the drag handle and actions menu in editable mode", :aggregate_failures do
    render_inline(described_class.new(attribute:, variant:, index: 0, total_count: 2))

    expect(page).to have_test_selector("type-form-configuration-attribute-handle-assignee")
    expect(page).to have_test_selector("type-form-configuration-attribute-actions-assignee")
    expect(page).to have_text("Assignee")
  end

  it "omits the handle and actions menu when readonly", :aggregate_failures do
    render_inline(described_class.new(attribute:, variant:, index: 0, total_count: 2, readonly: true))

    expect(page).to have_no_test_selector("type-form-configuration-attribute-handle-assignee")
    expect(page).to have_no_test_selector("type-form-configuration-attribute-actions-assignee")
    expect(page).to have_text("Assignee")
  end

  it "renders built-in attributes as secondary labels" do
    render_inline(described_class.new(attribute:, variant:, index: 0, total_count: 2, readonly: true))

    expect(page).to have_css(".Label.Label--secondary", text: I18n.t("label_builtin"))
  end

  # The switch itself is covered by ExclusionToggleComponent; what matters here is that the row
  # hands it this attribute's key and label, and asks for it only in read-only mode.
  describe "the exclusion toggle" do
    def render_row(exclusions:, readonly: true)
      render_inline(described_class.new(attribute:, variant:, index: 0, total_count: 2, readonly:, exclusions:))
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
      render_row(exclusions: WorkPackageTypes::ExclusionState
                               .new(variant:, own: [], effective: []))

      toggle = page.find("[data-test-selector='toggle-form-config-exclusion-assignee']")
      expect(toggle.find("button")["aria-label"]).to eq("Inherit Assignee")
    end
  end

  describe "custom field" do
    let(:attribute) do
      { key: "custom_field_5", is_cf: true, is_required: false, translation: "Alt description", field_format_label: "Text" }
    end

    it "shows a muted field format label" do
      render_inline(described_class.new(attribute:, variant:, index: 0, total_count: 2, readonly: true))

      expect(page).to have_css(".color-fg-muted.text-small", text: attribute[:field_format_label])
    end
  end
end
