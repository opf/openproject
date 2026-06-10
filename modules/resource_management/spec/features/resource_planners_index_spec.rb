# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Resource planners index" do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:viewer) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners] })
  end
  shared_let(:public_manager) do
    create(:user,
           member_with_permissions: { project => %i[view_resource_planners manage_public_resource_planners] })
  end
  shared_let(:non_member) { create(:user) }

  let(:current_user) { viewer }

  before do
    login_as(current_user)
    visit project_resource_planners_path(project)
  end

  context "without any planners" do
    it "renders the blankslate" do
      expect(page).to have_text(I18n.t("resource_management.blankslate.title"))
      expect(page).to have_text(I18n.t("resource_management.blankslate.desc"))
    end

    it "shows the create button to a permitted user" do
      expect(page).to have_link(text: I18n.t("resource_management.label_resource_planner"))
    end
  end

  context "with a mix of public and private planners" do
    shared_let(:my_private_planner) do
      create(:resource_planner, project:, principal: viewer, public: false, name: "My private")
    end
    shared_let(:other_private_planner) do
      create(:resource_planner, project:, principal: public_manager, public: false, name: "Other private")
    end
    shared_let(:public_planner) do
      create(:resource_planner, project:, principal: public_manager, public: true, name: "Shared planner")
    end

    context "as the owner / viewer" do
      it "lists my own private and the public planner, but not someone else's private one" do
        expect(page).to have_link("My private")
        expect(page).to have_link("Shared planner")
        expect(page).to have_no_link("Other private")
      end
    end

    context "as a non-member" do
      let(:current_user) { non_member }

      it "is denied access to the index" do
        # The :authorize before_action redirects unauthorized users away from
        # the project's resource planners page.
        expect(page).to have_no_link("Shared planner")
        expect(page).to have_no_link("My private")
      end
    end
  end
end
