# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkPackage do
  it "calculates exposure dynamically" do
    risk = build(:work_package, risk_likelihood: 25, risk_impact: 80_000)

    expect(risk.risk_exposure).to eq(20_000)
  end

  it "protects the built-in risk type from deletion" do
    risk_type = create(:type, builtin_identifier: "risk")

    expect(risk_type.destroy).to be(false)
    expect(risk_type.errors[:base]).to be_present
    expect(Type.exists?(risk_type.id)).to be(true)
  end
end
