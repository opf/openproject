# frozen_string_literal: true

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe TestManagement::TestCases::CreateContract do
  include_context "ModelContract shared context"

  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:test_case) { build(:tm_test_case, project:) }
  let(:contract) { described_class.new(test_case, current_user) }

  context "with add_test_cases permission" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_cases add_test_cases] }) }

    it_behaves_like "contract is valid"
  end

  context "with a folder of another project" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_cases add_test_cases] }) }

    before { test_case.suite = create(:tm_suite) }

    it_behaves_like "contract is invalid", suite_id: :invalid
  end

  context "with a folder of the same project" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_cases add_test_cases] }) }

    before { test_case.suite = create(:tm_suite, project:) }

    it_behaves_like "contract is valid"
  end

  context "without add_test_cases permission" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end
end
