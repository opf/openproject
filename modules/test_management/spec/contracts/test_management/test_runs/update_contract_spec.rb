# frozen_string_literal: true

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe TestManagement::TestRuns::UpdateContract do
  include_context "ModelContract shared context"

  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_runs add_test_runs] }) }
  let(:test_run) { create(:tm_test_run, project:) }
  let(:contract) { described_class.new(test_run, current_user) }

  before { test_run.name = "Renamed" }

  it_behaves_like "contract is valid"

  context "when the run is completed" do
    let(:test_run) { create(:tm_test_run, :completed, project:) }

    it_behaves_like "contract is invalid", base: :tm_run_finished
  end

  context "when the run is cancelled" do
    let(:test_run) { create(:tm_test_run, :cancelled, project:) }

    it_behaves_like "contract is invalid", base: :tm_run_finished
  end
end
