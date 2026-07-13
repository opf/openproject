# frozen_string_literal: true

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe Queries::UpdateContract do
  include_context "ModelContract shared context"

  let(:source_project) { create(:project) }
  let(:target_project) { create(:project) }
  let(:current_user) do
    create(:user, member_with_permissions: {
             source_project => %i[view_work_packages],
             target_project => %i[view_work_packages manage_public_queries]
           })
  end
  let!(:query) { create(:public_query, project: source_project, name: "Board list query") }

  subject(:contract) { described_class.new(query, current_user) }

  before do
    query.project = target_project
    query.name = "Renamed by attacker"
  end

  it_behaves_like "contract user is unauthorized"

  context "with manage_public_queries in both projects" do
    let(:current_user) do
      create(:user, member_with_permissions: {
               source_project => %i[view_work_packages manage_public_queries],
               target_project => %i[view_work_packages manage_public_queries]
             })
    end

    it_behaves_like "contract is valid"
  end
end
