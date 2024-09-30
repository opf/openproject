require "spec_helper"
require_relative "../../support/pages/ifc_models/show_default"

RSpec.describe "Copy work packages through Rails view", :js, :with_cuprite, with_config: { edition: "bim" } do
  shared_let(:project) { create(:project, name: "Source", enabled_module_names: %i[bim work_package_tracking]) }

  shared_let(:dev) do
    create(:user,
           firstname: "Dev",
           lastname: "Guy",
           member_with_permissions: { project => %i[view_work_packages work_package_assigned
                                                    view_ifc_models view_linked_issues] })
  end
  shared_let(:mover) do
    create(:user,
           firstname: "Manager",
           lastname: "Guy",
           member_with_permissions: {
             project => %i[view_work_packages view_ifc_models view_linked_issues
                           copy_work_packages move_work_packages manage_subtasks assign_versions edit_work_packages
                           add_work_packages]
           })
  end

  shared_let(:work_package) do
    create(:work_package, project:)
  end
  shared_let(:work_package2) do
    create(:work_package, project:)
  end

  let(:wp_table) { Pages::IfcModels::ShowDefault.new(project) }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }

  before do
    login_as current_user
    wp_table.visit!
    expect_angular_frontend_initialized
    wp_table.expect_work_package_listed work_package, work_package2

    wp_table.switch_view "Cards"
    loading_indicator_saveguard

    # Select all work packages
    find("body").send_keys [:control, "a"]
  end

  describe "accessing the bulk copy from the card view" do
    context "with permissions" do
      let(:current_user) { mover }

      it "does allow to copy" do
        context_menu.open_for work_package, card_view: true
        context_menu.expect_options "Bulk copy"
      end
    end

    context "without permission" do
      let(:current_user) { dev }

      it "does not allow to copy" do
        context_menu.open_for work_package, card_view: true
        context_menu.expect_no_options "Bulk copy"
      end
    end
  end

  describe "accessing the bulk move from the card view" do
    context "with permissions" do
      let(:current_user) { mover }

      it "does allow to move" do
        context_menu.open_for work_package, card_view: true
        context_menu.expect_options "Bulk change of project"
      end
    end

    context "without permission" do
      let(:current_user) { dev }

      it "does not allow to move" do
        context_menu.open_for work_package, card_view: true
        context_menu.expect_no_options "Bulk change of project"
      end
    end
  end

  describe "accessing the bulk edit from the card view" do
    context "with permissions" do
      let(:current_user) { mover }

      it "does allow to edit" do
        context_menu.open_for work_package, card_view: true
        context_menu.expect_options "Bulk edit"
      end

      context "with a project budget" do
        let!(:budget) { create(:budget, project:) }

        it "updates all the work packages" do
          context_menu.open_for work_package, card_view: true
          context_menu.choose "Bulk edit"

          select budget.subject, from: "work_package_budget_id"
          click_on "Submit"
          expect_and_dismiss_flash message: "Successful update."

          expect(work_package.reload.budget_id).to eq(budget.id)
          expect(work_package2.reload.budget_id).to eq(budget.id)
        end
      end
    end

    context "without permission" do
      let(:current_user) { dev }

      it "does not allow to edit" do
        context_menu.open_for work_package, card_view: true
        context_menu.expect_no_options "Bulk edit"
      end
    end
  end
end
