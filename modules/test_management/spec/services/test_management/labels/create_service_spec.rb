# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Labels::CreateService do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases manage_test_management]
           })
  end

  it "creates a normalized label" do
    result = described_class.new(user:).call(project:, name: "  Smoke  ", color: "danger")

    expect(result).to be_success
    expect(result.result.name).to eq("Smoke")
    expect(result.result.color).to eq("danger")
  end

  it "refuses without manage_test_management" do
    viewer = create(:user, member_with_permissions: { project => %i[view_test_cases] })

    result = described_class.new(user: viewer).call(project:, name: "Smoke")

    expect(result).to be_failure
  end
end
