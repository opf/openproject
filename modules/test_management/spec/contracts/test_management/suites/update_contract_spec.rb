# frozen_string_literal: true

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe TestManagement::Suites::UpdateContract do
  include_context "ModelContract shared context"

  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:current_user) { create(:user, member_with_permissions: { project => %i[view_test_cases manage_test_suites] }) }
  let!(:root) { create(:tm_suite, project:, name: "Root") }
  let!(:child) { create(:tm_suite, project:, parent: root, name: "Child") }
  let!(:grandchild) { create(:tm_suite, project:, parent: child, name: "Grandchild") }
  let(:contract) { described_class.new(suite, current_user) }

  context "when moving a folder below another folder" do
    let(:suite) { create(:tm_suite, project:).tap { |s| s.parent = grandchild } }

    it_behaves_like "contract is valid"
  end

  context "when moving a folder below itself" do
    let(:suite) { root.tap { |s| s.parent_id = root.id } }

    it_behaves_like "contract is invalid", parent_id: :invalid
  end

  context "when moving a folder below one of its descendants (cycle)" do
    let(:suite) { root.tap { |s| s.parent = grandchild } }

    it_behaves_like "contract is invalid", parent_id: :invalid
  end
end
