# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestStep do
  it "requires a non-negative integer position" do
    expect(build(:tm_test_step, position: -1)).not_to be_valid
    expect(build(:tm_test_step, position: 1.5)).not_to be_valid
    expect(build(:tm_test_step, position: 0)).to be_valid
  end

  it "is ordered under its test case" do
    test_case = create(:tm_test_case)
    second = create(:tm_test_step, test_case:, position: 1)
    first = create(:tm_test_step, test_case:, position: 0)

    expect(test_case.reload.steps).to eq([first, second])
  end
end
