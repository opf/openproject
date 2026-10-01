# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfigurationComponent, type: :component do
  include_context "with variant scope"

  let(:type) { create(:type, name: "Bug") }
  let(:base) { type.default_variant }
  let(:variant) { create(:type_variant, type:, variant_name: "Mobile app bug") }
  let(:no_filter_query) { "{}" }
  let(:context) { WorkPackageTypes::FormConfiguration::EditorContext.for_variant(variant, scope_project: nil) }
  let(:form_attributes) { ApplicationController.helpers.form_configuration_groups(context) }

  before do
    base.attribute_groups = [["Reused From Source", %w[assignee]]]
    base.save!
    login_as(create(:admin))
  end

  def render_component
    render_inline(described_class.new(context:, form_attributes:, no_filter_query:))
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
    it "renders read-only all the same, since the form is edited on its own page", :aggregate_failures do
      render_component

      expect(page).to have_no_css(".type-form-configuration-page--sidebar")
      expect(page).to have_no_test_selector("type-form-configuration-add-button")
    end

    it "renders nothing sortable for a read-only context" do
      expect(render_component).to have_no_css("[data-controller*='sortable-lists']")
    end
  end

  context "on the form's own page" do
    let(:form) { variant.form_configuration }
    let(:context) { WorkPackageTypes::FormConfiguration::EditorContext.new(form_configuration: form) }

    it "renders the editable page with the inactive sidebar", :aggregate_failures do
      render_component

      expect(page).to have_css(".type-form-configuration-page--sidebar")
    end

    it "wires one sortable-lists root next to the main controller", :aggregate_failures do
      expect(render_component)
        .to have_css("[data-controller~='sortable-lists'][data-controller~='admin--type-form-configuration--main']") do |root|
        templates = JSON.parse(root["data-sortable-lists-move-url-templates-value"])
        expect(templates).to eq(
          "group" => "/forms/#{form.id}/groups/{id}/move",
          "attribute" => "/forms/#{form.id}/attributes/{id}/move"
        )
        id = root["id"]
        expect(root["data-sortable-lists-sortable-lists--list-outlet"]).to eq("##{id} [data-controller~='sortable-lists--list']")
        expect(root["data-sortable-lists-sortable-lists--item-outlet"]).to eq("##{id} [data-controller~='sortable-lists--item']")
        expect(root["data-sortable-lists-sortable-lists--scrollable-outlet"])
          .to eq("##{id} [data-controller~='sortable-lists--scrollable']")
        expect(root["data-action"])
          .to include("sortable-lists:before-move->admin--type-form-configuration--main#confirmDiscardingEdit")
      end
    end

    it "lists groups and inactive attributes as separate destinations", :aggregate_failures do
      rendered = render_component

      expect(rendered).to have_css(
        "[data-sortable-lists--list-type-value='group'][data-sortable-lists--list-accepted-type-value='group']", count: 1
      )
      expect(rendered).to have_css(
        "[data-sortable-lists--list-type-value='inactive_attribute'][data-sortable-lists--list-accepted-type-value='attribute']",
        count: 1
      ) do |list|
        expect(list["data-sortable-lists--list-id-value"]).to be_nil
        expect(list.find(list["data-sortable-lists--list-rows-container-element"]).tag_name).to eq("ul")
      end
      expect(rendered).to have_css("[data-controller~='sortable-lists--scrollable']", count: 2)
    end
  end
end
