# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::CiTriggers::Request do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:root) { create(:tm_suite, project:, name: "Checkout") }
  shared_let(:child) { create(:tm_suite, project:, name: "Payment", parent: root) }
  shared_let(:in_root) { create(:tm_test_case, project:, suite: root, automation_reference: "tests/cart.spec.ts#adds (1) item") }
  shared_let(:in_child) { create(:tm_test_case, project:, suite: child, automation_reference: "tests/pay.spec.ts") }
  shared_let(:manual) { create(:tm_test_case, project:, suite: child) }
  shared_let(:deleted) do
    create(:tm_test_case, project:, suite: root, automation_reference: "tests/old.spec.ts#gone", deleted_at: Time.current)
  end

  it "collects the folder subtree and builds a regex-escaped grep" do
    request = described_class.new(project:, suite: root)
    expect(request.cases).to contain_exactly(in_root, in_child, manual)
    expect(request.automated_cases).to eq([in_root, in_child])
    expect(request.grep).to eq("adds\\ \\(1\\)\\ item|tests/pay\\.spec\\.ts")
    expect(request.scope_label).to eq("Checkout")
  end

  it "uses a single case or the cases of a run" do
    expect(described_class.new(project:, test_case: in_child).cases).to eq([in_child])
    run = create(:tm_test_run, project:)
    create(:tm_test_run_case, test_run: run, test_case: in_root)
    expect(described_class.new(project:, run:).cases).to eq([in_root])
  end

  it "sends an empty grep when the pattern is too long" do
    long = create_list(:tm_test_case, 3, project:, suite: root)
    long.each_with_index { |tc, i| tc.update_columns(automation_reference: "t.spec.ts##{'x' * 400}#{i}") }
    expect(described_class.new(project:, suite: root).grep).to eq("")
  end

  it "defaults the ref to the connection's ref" do
    connection = build(:tm_ci_connection, project:, trigger_ref: "develop")
    expect(described_class.new(project:, connection:).effective_ref).to eq("develop")
    expect(described_class.new(project:, connection:, ref: " v2 ").effective_ref).to eq("v2")
  end
end
