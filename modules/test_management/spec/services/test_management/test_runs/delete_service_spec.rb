# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestRuns::DeleteService do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases view_test_runs delete_test_runs]
           })
  end
  let(:test_run) { create(:tm_test_run, project:) }

  it "destroys the test run" do
    create(:tm_test_run_case, test_run:)
    id = test_run.id

    result = described_class.new(user:, model: test_run).call

    expect(result).to be_success
    expect(TestManagement::TestRun.find_by(id:)).to be_nil
  end

  it "refuses without delete_test_runs" do
    viewer = create(:user, member_with_permissions: {
                      project => %i[view_test_cases view_test_runs]
                    })

    result = described_class.new(user: viewer, model: test_run).call

    expect(result).to be_failure
    expect(TestManagement::TestRun.find_by(id: test_run.id)).to be_present
  end
end
