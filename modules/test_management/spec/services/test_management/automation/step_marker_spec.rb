# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Automation::StepMarker do
  it "reads the case step number from the supported markers" do
    expect(described_class.position_in("[step:3] Submit")).to eq(3)
    expect(described_class.position_in("[Step 3] Submit")).to eq(3)
    expect(described_class.position_in("Submit [step #12]")).to eq(12)
    expect(described_class.position_in("@S4 Pay")).to eq(4)
  end

  it "ignores titles without a marker and similar titles" do
    expect(described_class.position_in("Submit the form")).to be_nil
    expect(described_class.position_in("mail a@S4b")).to be_nil
    expect(described_class.position_in("[step:0] Nothing")).to be_nil
  end

  it "strips the marker from the stored title" do
    expect(described_class.strip("[step:2]  Enter the card")).to eq("Enter the card")
    expect(described_class.strip("@S2 Pay")).to eq("Pay")
  end
end
