# frozen_string_literal: true

require "spec_helper"

RSpec.describe RiskManagement::Configuration do
  subject(:configuration) do
    described_class.new(
      impact_very_low_max: 10_000,
      impact_low_max: 50_000,
      impact_medium_max: 100_000,
      impact_high_max: 500_000
    )
  end

  let!(:risk_type) { create(:type, builtin_identifier: "risk") }

  before { Setting.plugin_openproject_risk_management = {} }

  it "persists the impact thresholds" do
    expect(configuration.save).to be(true)

    Setting.clear_cache
    expect(Setting.plugin_openproject_risk_management).to include(
      "impact_very_low_max" => "10000",
      "impact_low_max" => "50000",
      "impact_medium_max" => "100000",
      "impact_high_max" => "500000"
    )
  end

  it "resolves the built-in risk type" do
    expect(configuration.risk_type).to eq(risk_type)
  end

  it "is invalid without the built-in risk type" do
    risk_type.update!(builtin_identifier: nil)

    expect(configuration).not_to be_valid
    expect(configuration.errors[:base]).to include("The built-in Risk work package type is not available.")
  end

  it "rejects unordered impact boundaries" do
    configuration.impact_medium_max = 50_000

    expect(configuration).not_to be_valid
    expect(configuration.errors[:base]).to be_present
  end
end
