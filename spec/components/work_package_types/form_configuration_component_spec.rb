# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfigurationComponent, type: :component do
  let(:source) { create(:type, name: "Bug") }
  let(:type) { create(:type, name: "Mobile app bug") }
  let(:no_filter_query) { "{}" }
  # The independent path renders whatever it is given; the read-only path ignores this and
  # resolves the source's groups itself, so a minimal shape is enough for both.
  let(:form_attributes) { { actives: [], inactives: [] } }

  before do
    source.attribute_groups = [["Reused From Source", %w[assignee]]]
    source.save!
    login_as(create(:admin))
  end

  def render_component
    render_inline(described_class.new(type:, form_attributes:, no_filter_query:))
  end

  context "when the form configuration aspect is linked (feature enabled)" do
    before do
      allow(OpenProject::FeatureDecisions).to receive(:subtypes_active?).and_return(true)
      type.link!(Type::ConfigurationLink::FORM_CONFIGURATION, source:)
    end

    it "renders the source's groups read-only", :aggregate_failures do
      render_component

      expect(page).to have_text("Reused From Source")
      expect(page).to have_no_css(".type-form-configuration-page--sidebar")
      expect(page).to have_no_test_selector("type-form-configuration-reset-button")
      expect(page).to have_no_test_selector("type-form-configuration-add-button")
      expect(page).to have_no_css("[data-draggable-type='group']")
    end
  end

  context "when independent" do
    before { allow(OpenProject::FeatureDecisions).to receive(:subtypes_active?).and_return(true) }

    it "renders the editable page with the inactive sidebar", :aggregate_failures do
      render_component

      expect(page).to have_css(".type-form-configuration-page--sidebar")
    end
  end

  context "when linked but the feature flag is off" do
    before do
      allow(OpenProject::FeatureDecisions).to receive(:subtypes_active?).and_return(false)
      type.link!(Type::ConfigurationLink::FORM_CONFIGURATION, source:)
    end

    it "renders the editable page (read-only branch not taken)", :aggregate_failures do
      render_component

      expect(page).to have_css(".type-form-configuration-page--sidebar")
    end
  end
end
