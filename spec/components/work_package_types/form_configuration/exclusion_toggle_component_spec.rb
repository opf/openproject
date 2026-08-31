# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfiguration::ExclusionToggleComponent, type: :component do
  let(:type) { create(:type) }
  let(:variant) { type.default_variant }

  def exclusion_state(effective: [])
    WorkPackageTypes::ExclusionState.new(variant:, own: effective, effective:)
  end

  def component(exclusions: exclusion_state, element_key: "assignee", label: "Inherit Assignee")
    described_class.new(exclusions:, element_key:, label:)
  end

  describe "#render?" do
    it "is false without exclusion state, which means the type owns its configuration" do
      expect(component(exclusions: nil).render?).to be(false)
    end

    it "is false without an element key, as for a query group whose query was deleted" do
      expect(component(element_key: nil).render?).to be(false)
    end

    it "is true once there is state and a key" do
      expect(component.render?).to be(true)
    end
  end

  describe "the rendered switch" do
    subject(:toggle) { page.find("[data-test-selector='toggle-form-config-exclusion-assignee']") }

    it "is on and posts to the element's toggle endpoint when nothing excludes it", :aggregate_failures do
      render_inline(component)

      expect(toggle.find("button")["aria-pressed"]).to eq("true")
      expect(toggle.find("button")["aria-label"]).to eq("Inherit Assignee")
      expect(toggle["src"]).to eq(
        "/types/#{type.id}/variants/#{variant.id}/exclusions/form_configuration/toggle?element=assignee"
      )
    end

    it "is off when the element is excluded" do
      render_inline(component(exclusions: exclusion_state(effective: %w[assignee])))

      expect(toggle.find("button")["aria-pressed"]).to eq("false")
    end

    it "keys the endpoint and selector on the element, not on an attribute name", :aggregate_failures do
      render_inline(component(element_key: "query_7", label: "Inherit section Related"))

      switch = page.find("[data-test-selector='toggle-form-config-exclusion-query_7']")
      expect(switch["src"]).to eq(
        "/types/#{type.id}/variants/#{variant.id}/exclusions/form_configuration/toggle?element=query_7"
      )
      expect(switch.find("button")["aria-label"]).to eq("Inherit section Related")
    end
  end
end
