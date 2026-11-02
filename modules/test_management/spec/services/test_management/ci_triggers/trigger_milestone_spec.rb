# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::CiTriggers::TriggerService, "milestone", :disable_ssrf_filter, :webmock do
  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_test_cases view_test_runs add_test_runs trigger_test_automation] })
  end
  shared_let(:suite) { create(:tm_suite, project:) }
  shared_let(:automated) { create(:tm_test_case, project:, suite:, automation_reference: "tests/cart.spec.ts#adds item") }
  shared_let(:connection) { create(:tm_ci_connection, :github_trigger, project:) }

  before do
    stub_request(:post, "https://api.github.com/repos/my-org/shop/actions/workflows/e2e.yml/dispatches").to_return(status: 204)
  end

  it "assigns the pre-created run to the milestone" do
    milestone = create(:tm_milestone, project:, name: "Release 2.0")

    call = described_class.new(user:).call(project:, connection:, suite:, milestone:)

    expect(call).to be_success
    expect(call.result.run.reload.milestone).to eq(milestone)
  end

  it "creates nothing for a completed milestone" do
    milestone = create(:tm_milestone, :completed, project:)

    call = described_class.new(user:).call(project:, connection:, suite:, milestone:)

    expect(call).to be_failure
    expect(TestManagement::TestRun.where(project_id: project.id)).to be_empty
  end
end
