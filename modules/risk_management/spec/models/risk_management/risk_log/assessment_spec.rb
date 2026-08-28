# frozen_string_literal: true

require "spec_helper"

RSpec.describe RiskManagement::RiskLog::Assessment do
  let(:configuration) do
    RiskManagement::Configuration.new(
      impact_very_low_max: 10_000,
      impact_low_max: 50_000,
      impact_medium_max: 100_000,
      impact_high_max: 500_000
    )
  end

  it "calculates the expected monetary risk value" do
    assessment = described_class.new(likelihood: 25, impact: 80_000, configuration:)

    expect(assessment.risk_value).to eq(20_000)
    expect(assessment.coordinate).to eq([2, 3])
    expect(assessment.risk_level).to eq(:medium)
  end

  it "classifies high and critical risks from the matrix score" do
    high = described_class.new(likelihood: 70, impact: 90_000, configuration:)
    critical = described_class.new(likelihood: 90, impact: 600_000, configuration:)

    expect(high).to be_high_or_critical
    expect(high.risk_level).to eq(:high)
    expect(critical.risk_level).to eq(:critical)
  end

  it "does not evaluate missing or out-of-range values" do
    missing = described_class.new(likelihood: nil, impact: 50_000, configuration:)
    invalid = described_class.new(likelihood: 101, impact: 50_000, configuration:)

    expect(missing).not_to be_evaluated
    expect(missing.risk_value).to be_nil
    expect(invalid).not_to be_evaluated
  end
end
