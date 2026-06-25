# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResourcePlanners::ShowPageHeaderComponent, type: :component do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:owner) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners] })
  end
  shared_let(:public_manager) do
    create(:user,
           member_with_permissions: { project => %i[view_resource_planners manage_public_resource_planners] })
  end

  let(:resource_planner) { create(:resource_planner, project:, principal: owner, public: false, name: "My planner") }
  let(:current_user) { owner }

  subject(:rendered) do
    login_as(current_user)
    render_inline(described_class.new(resource_planner:, project:))
    page
  end

  it "renders the planner title" do
    expect(rendered).to have_text("My planner")
  end

  context "as the owner" do
    it "renders the edit and delete actions" do
      expect(rendered).to have_css("[data-test-selector='resource-planner-edit']")
      expect(rendered).to have_css("[data-test-selector='resource-planner-delete']")
    end

    it "renders the favorite toggle" do
      expect(rendered).to have_css("[data-test-selector='resource-planner-favorite']")
    end
  end

  context "when the planner is favorited by the user" do
    before { resource_planner.add_favoriting_user(owner) }

    it "renders the unfavorite toggle" do
      expect(rendered).to have_css("[data-test-selector='resource-planner-unfavorite']")
      expect(rendered).to have_no_css("[data-test-selector='resource-planner-favorite']")
    end
  end

  context "as a user who cannot manage the planner" do
    let(:current_user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners] })
    end
    let(:resource_planner) do
      create(:resource_planner, project:, principal: public_manager, public: true, name: "Shared planner")
    end

    it "hides the edit and delete actions" do
      expect(rendered).to have_no_css("[data-test-selector='resource-planner-edit']")
      expect(rendered).to have_no_css("[data-test-selector='resource-planner-delete']")
    end

    it "still offers the favorite toggle" do
      expect(rendered).to have_css("[data-test-selector='resource-planner-favorite']")
    end
  end
end
