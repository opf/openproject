# frozen_string_literal: true

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe TestManagement::Suites::CreateContract do
  include_context "ModelContract shared context"

  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_cases manage_test_suites] }) }
  let(:suite) { build(:tm_suite, project:) }
  let(:contract) { described_class.new(suite, current_user) }

  it_behaves_like "contract is valid"

  context "with a parent folder in the same project" do
    before { suite.parent = create(:tm_suite, project:) }

    it_behaves_like "contract is valid"
  end

  context "with a parent folder from another project" do
    before { suite.parent = create(:tm_suite) }

    it_behaves_like "contract is invalid", parent_id: :invalid
  end

  context "without manage_test_suites" do
    let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_cases] }) }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end
end
