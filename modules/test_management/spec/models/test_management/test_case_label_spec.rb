# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestCaseLabel do
  let(:link) { create(:tm_test_case_label) }

  it "links a test case and a label" do
    expect(link.test_case.labels).to contain_exactly(link.label)
    expect(link.label.test_cases).to contain_exactly(link.test_case)
  end

  it "does not link the same label twice" do
    duplicate = described_class.new(test_case: link.test_case, label: link.label)
    expect(duplicate).not_to be_valid
  end

  it "is removed when the test case is destroyed" do
    link.test_case.destroy
    expect(described_class.where(id: link.id)).to be_empty
  end
end
