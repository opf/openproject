require "spec_helper"
require "features/page_objects/notification"
require "support/components/autocompleter/ng_select_autocomplete_helpers"

RSpec.describe "Moving a work package through Rails view", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  let(:dev_role) do
    create(:project_role,
           permissions: %i[view_work_packages add_work_packages])
  end
  let(:mover_role) do
    create(:project_role,
           permissions: %i[view_work_packages move_work_packages manage_subtasks add_work_packages])
  end
  let(:dev) do
    create(:user,
           firstname: "Dev",
           lastname: "Guy",
           member_with_roles: { project => dev_role })
  end
  let(:mover) do
    create(:admin,
           firstname: "Manager",
           lastname: "Guy",
           member_with_roles: { project => mover_role })
  end

  let(:type) { create(:type, name: "Bug") }
  let(:type2) { create(:type, name: "Risk") }

  let!(:project) { create(:project, name: "Source", types: [type, type2]) }
  let!(:project2) { create(:project, name: "Target", types: [type, type2]) }

  let(:work_package) do
    create(:work_package,
           author: dev,
           project:,
           type:,
           status:)
  end
  let(:work_package2) do
    create(:work_package,
           author: dev,
           project:,
           type:,
           status: work_package2_status)
  end
  let(:status) { create(:status) }
  let(:work_package2_status) { status }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let(:context_menu) { Components::WorkPackages::ContextMenu.new }
  let(:current_user) { mover }
  let(:work_packages) { [work_package, work_package2] }

  before do
    work_packages
    login_as current_user
    wp_table.visit!
    expect_angular_frontend_initialized
  end

  describe "moving a work package and its children" do
    let(:work_packages) { [work_package, child_wp] }
    let(:child_wp) do
      create(:work_package,
             author: dev,
             parent: work_package,
             project:,
             type:,
             status:)
    end

    context "with permission" do
      before do
        expect(child_wp.project_id).to eq(project.id)

        context_menu.open_for work_package
        context_menu.choose "Move to another project"

        # On work packages move page
        expect(page).to have_css("#new_project_id")
        select_autocomplete page.find_test_selector("new_project_id"),
                            query: "Target",
                            select_text: "Target",
                            results_selector: "body"
        if using_cuprite?
          wait_for_network_idle
        else
          SeleniumHubWaiter.wait
        end
      end

      context "when the limit to move in the frontend is 1",
              with_settings: { work_packages_bulk_request_limit: 1 } do
        it "copies them in the background and shows a status page", :with_cuprite do
          click_on "Move and follow"
          wait_for_reload

          expect(page).to have_text("The job has been queued and will be processed shortly.", wait: 10)

          perform_enqueued_jobs

          work_package.reload
          expect(work_package.project_id).to eq(project2.id)

          expect(page).to have_current_path "/projects/#{project2.identifier}/work_packages/#{work_package.id}/activity"
          page.find_by_id("projects-menu", text: "Target")
        end
      end

      it "moves parent and child wp to a new project", :with_cuprite do
        click_on "Move and follow"
        wait_for_reload
        page.find(".inline-edit--container.subject", text: work_package.subject)
        page.find_by_id("projects-menu", text: "Target")

        # Should move its children
        child_wp.reload
        expect(child_wp.project_id).to eq(project2.id)
      end

      context "when the target project does not have the type" do
        let!(:project2) { create(:project, name: "Target", types: [type2]) }

        it "does not move the work package", :with_cuprite do
          click_on "Move and follow"
          wait_for_reload

          expect(page)
            .to have_css(".op-toast.-error",
                         text: I18n.t(:"work_packages.bulk.none_could_be_saved",
                                      total: 1))

          # Should NOT have moved
          child_wp.reload
          work_package.reload
          expect(work_package.project_id).to eq(project.id)
          expect(work_package.type_id).to eq(type.id)
          expect(child_wp.project_id).to eq(project.id)
          expect(child_wp.type_id).to eq(type.id)
        end
      end

      context "when the target project has a type with a required field" do
        let(:required_cf) { create(:integer_wp_custom_field, is_required: true) }
        let(:type2) { create(:type, name: "Risk", custom_fields: [required_cf]) }
        let!(:project2) { create(:project, name: "Target", types: [type2], work_package_custom_fields: [required_cf]) }

        it "does not moves the work package when the required field is missing" do
          select "Risk", from: "Type"
          expect(page).to have_field(required_cf.name)

          # Clicking move and follow might be broken due to the location.href
          # in the refresh-on-form-changes component
          retry_block do
            click_on "Move and follow"
          end

          expect(page)
            .to have_css(".op-toast.-error",
                         text: I18n.t(:"work_packages.bulk.none_could_be_saved",
                                      total: 1))
          child_wp.reload
          work_package.reload
          expect(work_package.project_id).to eq(project.id)
          expect(work_package.type_id).to eq(type.id)
          expect(child_wp.project_id).to eq(project.id)
          expect(child_wp.type_id).to eq(type.id)
        end
      end
    end

    context "without permission" do
      let(:current_user) { dev }

      it "does not allow to move" do
        context_menu.open_for work_package
        context_menu.expect_no_options "Move to another project"
      end
    end
  end

  describe "moving an unmovable (e.g. readonly status) and a movable work package", with_ee: %i[readonly_work_packages] do
    let(:work_packages) { [work_package, work_package2] }
    let(:work_package2_status) { create(:status, is_readonly: true) }

    before do
      loading_indicator_saveguard
      # Select all work packages
      find("body").send_keys [:control, "a"]

      context_menu.open_for work_package2
      context_menu.choose "Bulk change of project"

      # On work packages move page
      select_autocomplete page.find_test_selector("new_project_id"),
                          query: project2.name,
                          select_text: project2.name,
                          results_selector: "body"
      click_on "Move and follow"
    end

    it "displays an error message explaining which work package could not be moved and why" do
      expect(page)
        .to have_css(".op-toast.-error",
                     text: I18n.t("work_packages.bulk.could_not_be_saved"),
                     wait: 10)

      expect(page)
        .to have_css(
          ".op-toast.-error",
          text: "#{work_package2.id}: Project #{I18n.t('activerecord.errors.messages.error_readonly')}"
        )

      expect(page)
        .to have_css(".op-toast.-error",
                     text: I18n.t("work_packages.bulk.x_out_of_y_could_be_saved",
                                  failing: 1,
                                  total: 2,
                                  success: 1))

      expect(work_package.reload.project_id).to eq(project2.id)
      expect(work_package2.reload.project_id).to eq(project.id)
    end
  end
end
