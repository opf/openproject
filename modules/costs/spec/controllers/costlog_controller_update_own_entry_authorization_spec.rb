# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe CostlogController, "update authorization for own-entry permissions" do
  include Cost::PluginSpecHelper

  let(:project) { create(:project_with_types) }
  let(:victim) { create(:user) }
  let(:acting_user) { create(:user) }
  let(:work_package) do
    create(:work_package, project:, author: victim, type: project.types.first)
  end
  let(:cost_type) { create(:cost_type) }
  let!(:cost_entry) do
    create(:cost_entry,
           entity: work_package,
           project:,
           user: victim,
           cost_type:,
           units: 10,
           spent_on: Date.current)
  end

  before do
    is_member(project, acting_user, %i[view_project view_work_packages view_cost_entries edit_own_cost_entries])
    allow(User).to receive(:current).and_return(acting_user)
    allow(controller).to receive(:check_if_login_required)
    allow(controller.flash).to receive(:sweep)
  end

  after do
    User.current = nil
  end

  describe "PUT update" do
    let(:params) do
      {
        id: cost_entry.id.to_s,
        cost_entry: {
          user_id: acting_user.id.to_s,
          entity_type: "WorkPackage",
          entity_id: work_package.id.to_s,
          cost_type_id: cost_type.id.to_s,
          units: "99",
          spent_on: cost_entry.spent_on.to_s,
          comments: "reassigned through own-entry permission"
        }
      }
    end

    it "rejects reassignment of another user's entry to the acting user" do
      put :update, params: params

      expect(response).to have_http_status(:forbidden)
      expect(cost_entry.reload.user).to eq(victim)
      expect(cost_entry.units).to eq(10)
    end
  end
end
