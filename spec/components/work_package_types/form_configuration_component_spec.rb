# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfigurationComponent, type: :component do
  let(:type) { create(:type, name: "Bug") }
  let(:base) { type.default_variant }
  let(:variant) { create(:type_variant, type:, variant_name: "Mobile app bug") }
  let(:no_filter_query) { "{}" }
  # The independent path renders whatever it is given; the read-only path ignores this and
  # resolves the base's groups itself, so a minimal shape is enough for both.
  let(:form_attributes) { { actives: [], inactives: [] } }

  before do
    base.attribute_groups = [["Reused From Source", %w[assignee]]]
    base.save!
    login_as(create(:admin))
  end

  def render_component
    render_inline(described_class.new(variant:, form_attributes:, no_filter_query:))
  end

  context "when the form configuration aspect is linked" do
    before do
      link_configuration(variant, aspect: TypeVariant::FORM_CONFIGURATION)
    end

    it "renders the base's groups read-only", :aggregate_failures do
      render_component

      expect(page).to have_text("Reused From Source")
      expect(page).to have_no_css(".type-form-configuration-page--sidebar")
      expect(page).to have_no_test_selector("type-form-configuration-reset-button")
      expect(page).to have_no_test_selector("type-form-configuration-add-button")
      expect(page).to have_no_css("[data-draggable-type='group']")
    end

    # An exclusion the variant owns is reversible from here, so its row stays and the switch
    # shows it off.
    describe "exclusions" do
      before do
        base.attribute_groups = [["People", %w[assignee responsible]]]
        base.save!
      end

      it "lists a row the variant excludes itself, switched off", :aggregate_failures do
        exclude_configuration_elements(variant, aspect: TypeVariant::FORM_CONFIGURATION, elements: %w[assignee])

        render_component

        expect(page).to have_text("People")
        toggle = page.find("[data-test-selector='toggle-form-config-exclusion-assignee'] > button")
        expect(toggle["aria-pressed"]).to eq("false")
      end

      it "renders a query section nothing excludes" do
        base.attribute_groups = [["People", %w[assignee]], ["Related", [create(:query)]]]
        base.save!

        render_component

        expect(page).to have_text("Related")
      end
    end
  end

  context "when independent" do
    it "renders the editable page with the inactive sidebar", :aggregate_failures do
      render_component

      expect(page).to have_css(".type-form-configuration-page--sidebar")
    end
  end
end
