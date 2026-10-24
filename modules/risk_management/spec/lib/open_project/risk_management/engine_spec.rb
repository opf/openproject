# frozen_string_literal: true

require "spec_helper"

RSpec.describe OpenProject::RiskManagement::Engine do
  let(:project) { create(:project) }
  let!(:risk_type) { create(:type, name: "Risk", builtin_identifier: "risk") }

  it "activates and deactivates the built-in risk type with the module" do
    project.enabled_module_names |= ["risk_log"]

    expect(project.reload.enabled_types).to include(risk_type)

    project.enabled_module_names -= ["risk_log"]

    expect(project.reload.enabled_types).not_to include(risk_type)
  end

  it "only enables the core risk attributes for the built-in risk type" do
    regular_type = create(:type)

    expect(risk_type.default_variant.passes_attribute_constraint?(:risk_owner)).to be(true)
    expect(regular_type.default_variant.passes_attribute_constraint?(:risk_owner)).to be(false)
  end
end
