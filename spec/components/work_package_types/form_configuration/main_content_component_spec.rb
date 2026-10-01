# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfiguration::MainContentComponent, type: :component do
  let(:variant) { create(:type).default_variant }

  def editor_context(readonly: false, exclusions: nil)
    WorkPackageTypes::FormConfiguration::EditorContext.for_variant(variant, scope_project: nil).tap do |context|
      allow(context).to receive_messages(readonly?: readonly, exclusions:)
    end
  end

  it "renders Reset and Add actions in editable EE mode", :aggregate_failures do
    render_inline(described_class.new(context: editor_context, group_components: [], ee_available: true))

    expect(page).to have_test_selector("type-form-configuration-reset-button")
    expect(page).to have_test_selector("type-form-configuration-add-button")
  end

  it "omits Reset, Add, and drag targets when readonly", :aggregate_failures do
    render_inline(described_class.new(context: editor_context(readonly: true), group_components: [], ee_available: true))

    expect(page).to have_no_test_selector("type-form-configuration-reset-button")
    expect(page).to have_no_test_selector("type-form-configuration-add-button")
    expect(page).to have_no_css("[data-controller*='sortable-lists']")
    expect(page).to have_test_selector("type-form-configuration-groups-container")
  end

  describe "the groups container" do
    subject(:rendered_component) do
      render_inline(described_class.new(context: editor_context, group_components: [], ee_available: true))
    end

    it_behaves_like "a sortable-lists list", list_type: "group", name: nil
  end
end
