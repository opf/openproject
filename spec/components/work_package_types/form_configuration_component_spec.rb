# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfigurationComponent, type: :component do
  let(:source_type) { create(:type, name: "Bug") }
  let(:source) { source_type.default_variant }
  let(:type) { create(:type, name: "Mobile app bug") }
  let(:variant) { type.default_variant }
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
    render_inline(described_class.new(variant:, form_attributes:, no_filter_query:))
  end

  context "when the form configuration aspect is linked (feature enabled)" do
    before do
      allow(OpenProject::FeatureDecisions).to receive(:type_variants_active?).and_return(true)
      link_configuration(variant, source:, aspect: TypeVariant::FORM_CONFIGURATION)
    end

    it "renders the source's groups read-only", :aggregate_failures do
      render_component

      expect(page).to have_text("Reused From Source")
      expect(page).to have_no_css(".type-form-configuration-page--sidebar")
      expect(page).to have_no_test_selector("type-form-configuration-reset-button")
      expect(page).to have_no_test_selector("type-form-configuration-add-button")
      expect(page).to have_no_css("[data-draggable-type='group']")
    end

    # An exclusion this type owns is reversible from here, so its row stays and the switch shows
    # it off. One coming from a link above it is not, so the row is left out instead.
    describe "exclusions" do
      let(:link) { variant }

      before do
        source.attribute_groups = [["People", %w[assignee responsible]]]
        source.save!
      end

      it "lists a row this type excludes itself, switched off", :aggregate_failures do
        exclude_configuration_elements(link, aspect: TypeVariant::FORM_CONFIGURATION, elements: %w[assignee])

        render_component

        expect(page).to have_text("People")
        toggle = page.find("[data-test-selector='toggle-form-config-exclusion-assignee'] > button")
        expect(toggle["aria-pressed"]).to eq("false")
      end

      it "omits a row an ancestor's link excludes", :aggregate_failures do
        middle = create(:type, name: "Middle")
        link_configuration(link, source: middle, aspect: TypeVariant::FORM_CONFIGURATION)
        link_configuration(middle, source: source, aspect: TypeVariant::FORM_CONFIGURATION, excluded: %w[assignee])

        render_component

        expect(page).to have_text("People")
        expect(page).to have_no_test_selector("toggle-form-config-exclusion-assignee")
        expect(page).to have_test_selector("toggle-form-config-exclusion-responsible")
      end

      # Paired with the example below on purpose: it proves the section name renders at all, so
      # the absence asserted there is the exclusion doing its job.
      it "renders a query section nothing excludes" do
        source.attribute_groups = [["People", %w[assignee]], ["Related", [create(:query)]]]
        source.save!

        render_component

        expect(page).to have_text("Related")
      end

      it "drops a query section an ancestor's link excludes", :aggregate_failures do
        query = create(:query, name: "Embedded list")
        source.attribute_groups = [["People", %w[assignee]], ["Related", [query]]]
        source.save!

        middle = create(:type, name: "Middle")
        link_configuration(link, source: middle, aspect: TypeVariant::FORM_CONFIGURATION)
        link_configuration(middle, source: source, aspect: TypeVariant::FORM_CONFIGURATION, excluded: ["query_#{query.id}"])

        render_component

        expect(page).to have_text("People")
        expect(page).to have_no_text("Related")
      end

      it "drops a group an ancestor's exclusions empty" do
        middle = create(:type, name: "Middle")
        link_configuration(link, source: middle, aspect: TypeVariant::FORM_CONFIGURATION)
        link_configuration(middle, source: source, aspect: TypeVariant::FORM_CONFIGURATION, excluded: %w[assignee responsible])

        render_component

        expect(page).to have_no_text("People")
      end
    end
  end

  context "when independent" do
    before { allow(OpenProject::FeatureDecisions).to receive(:type_variants_active?).and_return(true) }

    it "renders the editable page with the inactive sidebar", :aggregate_failures do
      render_component

      expect(page).to have_css(".type-form-configuration-page--sidebar")
    end
  end

  context "when linked but the feature flag is off" do
    before do
      allow(OpenProject::FeatureDecisions).to receive(:type_variants_active?).and_return(false)
      link_configuration(variant, source:, aspect: TypeVariant::FORM_CONFIGURATION)
    end

    it "renders the editable page (read-only branch not taken)", :aggregate_failures do
      render_component

      expect(page).to have_css(".type-form-configuration-page--sidebar")
    end
  end
end
