# frozen_string_literal: true

require "spec_helper"

require "support/edit_fields/edit_field"

RSpec.describe "Relations children tab", :js, :with_cuprite do
  include CustomFieldsHelpers

  shared_let(:normal_cf) { create(:string_wp_custom_field, is_required: false) }
  shared_let(:required_cf) { create(:string_wp_custom_field, is_required: true) }
  shared_let(:type_milestone) { create(:type_milestone) }
  shared_let(:type_task) { create(:type, name: "Task", custom_fields: [normal_cf]) }
  shared_let(:type_risk) { create(:type, name: "Risk", custom_fields: [required_cf]) }
  shared_let(:default_status) { create(:default_status) }
  shared_let(:default_priority) { create(:default_priority) }

  shared_let(:project) do
    create(:project,
           types: [type_task, type_risk, type_milestone],
           work_package_custom_fields: [normal_cf, required_cf])
  end

  shared_let(:work_package) { create(:work_package, type: type_task, project:, subject: "Parent") }

  let(:relations_tab) { Components::WorkPackages::Relations.new(work_package) }
  let(:create_dialog) { Components::WorkPackages::CreateDialog.new }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }

  current_user { user }

  context "with permissions to add children" do
    let!(:user) do
      create(:user, member_with_permissions: { project => %i[view_work_packages add_work_packages manage_subtasks] })
    end

    it "can add a new child" do
      wp_page.visit_tab!("relations")
      relations_tab.expect_add_relation_button
      relations_tab.expect_new_relation_type("Create new child")
      relations_tab.expect_new_relation_type("Child")

      relations_tab.select_relation_type "Create new child"

      create_dialog.select_type "Task"
      create_dialog.set_subject "Hello there"
      create_dialog.set_description "Some *markdown* content"
      create_dialog.expect_no_custom_field(normal_cf)

      create_dialog.select_type "Risk"
      # Retains subject and description
      create_dialog.expect_subject "Hello there"
      create_dialog.expect_description "Some markdown content"

      # Shows a custom field
      create_dialog.set_custom_field(required_cf, "Custom value")
      create_dialog.submit

      wait_for_network_idle

      expect_and_dismiss_flash type: :success, exact_message: "New work package created and added as a child"

      page.within("#work-package-relations-tab-content") do
        expect(page).to have_content("Hello there")
        expect(page).to have_content("RISK")
      end
    end

    context "when being on the split screen" do
      let(:wp_split_page) { Pages::SplitWorkPackage.new(work_package, project) }

      it "can render the page correctly after creation (regression #60629)" do
        wp_split_page.visit_tab!("relations")
        relations_tab.expect_add_relation_button
        relations_tab.expect_new_relation_type("Create new child")
        relations_tab.expect_new_relation_type("Child")

        relations_tab.select_relation_type "Create new child"

        create_dialog.select_type "Risk"
        create_dialog.set_subject "Hello there"
        create_dialog.set_custom_field(required_cf, "Custom value")

        create_dialog.submit

        wait_for_network_idle

        expect_and_dismiss_flash type: :success, exact_message: "New work package created and added as a child"

        page.within("#work-package-relations-tab-content") do
          expect(page).to have_content("Hello there")
          expect(page).to have_content("RISK")
        end

        expect(page).to have_css("body.router--work-packages-partitioned-split-view-details")
      end
    end

    context "when work package is a milestone and user does not have manage_work_package_relations permission" do
      let(:work_package) { create(:work_package, type: type_milestone, project:, subject: "Milestone") }

      it "shows only the action to add a parent" do
        wp_page.visit_tab!("relations")
        relations_tab.expect_add_relation_button
        relations_tab.expect_no_new_relation_type("Related To")
        relations_tab.expect_no_new_relation_type("Child")
        relations_tab.expect_no_new_relation_type("Create new child")
        relations_tab.expect_new_relation_type("Parent")
      end
    end

    context "when work package is a milestone and user has manage_work_package_relations permission" do
      let!(:user) do
        create(:user,
               member_with_permissions: {
                 project => %i[view_work_packages manage_subtasks manage_work_package_relations]
               })
      end
      let(:work_package) { create(:work_package, type: type_milestone, project:, subject: "Milestone") }

      it "shows the menu, but not the child actions" do
        wp_page.visit_tab!("relations")
        relations_tab.expect_add_relation_button
        relations_tab.expect_new_relation_type("Related to")
        relations_tab.expect_no_new_relation_type("Child")
        relations_tab.expect_no_new_relation_type("Create new child")
        relations_tab.expect_new_relation_type("Parent")
      end
    end

    context "in status-based progress calculation mode (bug #61551)",
            with_settings: { work_package_done_ratio: "status" } do
      it "can add a new child" do
        wp_page.visit_tab!("relations")
        relations_tab.select_relation_type "Create new child"

        create_dialog.select_type "Task"
        create_dialog.set_subject "Hello there"
        create_dialog.submit

        wait_for_network_idle

        expect_and_dismiss_flash type: :success, exact_message: "New work package created and added as a child"

        page.within("#work-package-relations-tab-content") do
          expect(page).to have_content("Hello there")
          expect(page).to have_content("TASK")
        end
      end
    end
  end

  context "without permissions to add children or parent (:manage_subtasks)" do
    let!(:user) do
      create(:user, member_with_permissions: { project => %i[view_work_packages] })
    end

    it "does not show the action" do
      wp_page.visit_tab!("relations")
      relations_tab.expect_no_add_relation_button
    end
  end

  context "with permission to manage_subtasks, but not add_work_packages" do
    let!(:user) do
      create(:user, member_with_permissions: { project => %i[view_work_packages manage_subtasks] })
    end

    it "shows an action to add 'Child' or 'Parent', but not to 'Create new child'" do
      wp_page.visit_tab!("relations")
      relations_tab.expect_add_relation_button
      relations_tab.expect_new_relation_type("Child")
      relations_tab.expect_no_new_relation_type("Create new child")
      relations_tab.expect_new_relation_type("Parent")
    end
  end

  context "when all possible custom fields are there" do
    shared_let(:user) { create(:admin) }
    shared_let(:all_possible_custom_fields) do
      factory_bot_custom_field_traits_for("WorkPackage")
        .product([true, false])
        .map do |trait, is_required|
          create(:wp_custom_field, trait, is_required:)
        end
    end

    before do
      all_possible_custom_fields.each do |cf|
        project.types.first.custom_fields << cf
        project.work_package_custom_fields << cf
      end
    end

    it "displays a field for each required custom field" do
      wp_page.visit_tab!("relations")
      relations_tab.select_relation_type "Create new child"

      all_possible_custom_fields.each do |cf|
        create_dialog.in_dialog do
          if cf.required?
            # `visible: :all` is needed as text custom field use a hidden textarea internally
            expect(page).to have_field cf.name, visible: :all
          else
            expect(page).to have_no_field cf.name
          end
        end
      end
    end

    it "focuses the subject input field" do
      wp_page.visit_tab!("relations")
      relations_tab.select_relation_type "Create new child"

      create_dialog.expect_subject_field_focused
    end
  end
end
