require "spec_helper"
require "support/edit_fields/edit_field"
require "features/work_packages/work_packages_page"
require "features/page_objects/notification"

RSpec.describe "new work package", :js, :with_cuprite do
  shared_let(:status) { create(:status, is_default: true) }
  shared_let(:priority) { create(:priority, is_default: true) }
  shared_let(:type_task) { create(:type_task) }
  shared_let(:type_milestone) { create(:type_milestone, position: type_task.position + 1) }
  shared_let(:type_bug) { create(:type_bug, position: type_milestone.position + 1) }
  shared_let(:types) { [type_task, type_milestone, type_bug] }
  shared_let(:project) do
    create(:project, types:)
  end

  let(:permissions) { %i[view_work_packages add_work_packages edit_work_packages work_package_assigned] }
  let(:user) do
    create(:user, member_with_permissions: { project => permissions })
  end

  let(:work_packages_page) { WorkPackagesPage.new(project) }

  let(:subject) { "My subject" }
  let(:description) { "A description of the newly-created work package." }

  let(:subject_field) { wp_page.edit_field :subject }
  let(:description_field) { wp_page.edit_field :description }
  let(:project_field) { wp_page.edit_field :project }
  let(:assignee_field) { wp_page.edit_field :assignee }
  let(:type_field) { wp_page.edit_field :type }
  let(:toaster) { PageObjects::Notifications.new(page) }

  def disable_leaving_unsaved_warning
    create(:user_preference, user:, others: { warn_on_leaving_unsaved: false })
  end

  def save_work_package!(expect_success = true)
    scroll_to_and_click find_by_id("work-packages--edit-actions-save")

    if expect_success
      toaster.expect_success("Successful creation.")
    end
  end

  def click_create_work_package_button(type)
    loading_indicator_saveguard

    wp_page.click_create_wp_button(type)

    loading_indicator_saveguard
  end

  def create_work_package(type, *)
    click_create_work_package_button(type)
    expect(page).to have_focus_on("#wp-new-inline-edit--field-subject")
    wp_page.subject_field.set(subject)

    wait_for_network_idle
  end

  def create_work_package_globally(type, project_name)
    click_create_work_package_button(type)

    wp_page.subject_field.set(subject)

    project_field.openSelectField
    project_field.set_value project_name

    wait_for_network_idle

    # Select self as assignee
    assignee_field.openSelectField
    assignee_field.set_value user.name

    wait_for_network_idle
  end

  before do
    disable_leaving_unsaved_warning
    login_as(user)
  end

  shared_examples "work package creation workflow" do
    before do
      create_method.call(type_task, project.name)

      expect(page).to have_selector(safeguard_selector, wait: 10)
    end

    it "creates a subsequent work package" do
      wp_page.subject_field.set(subject)
      save_work_package!

      # safeguards
      wp_page.dismiss_toaster!
      wp_page.expect_no_toaster(
        message: "Successful creation."
      )

      subject_field.expect_state_text(subject)

      create_method.call(type_bug, project.name)
      expect(page).to have_selector(safeguard_selector, wait: 10)

      # Use regex to not be case sensitive
      type_field.expect_state_text /#{type_bug.name}/i
    end

    it "saves the work package with enter" do
      subject_field = wp_page.subject_field
      subject_field.set(subject)
      subject_field.send_keys(:enter)

      # safeguards
      wp_page.dismiss_toaster!
      wp_page.expect_no_toaster(
        message: "Successful creation."
      )

      wp_page.edit_field(:subject).expect_text(subject)
    end

    context "with missing values" do
      it "shows an error when subject is missing" do
        description_field.set_value(description)

        # Need to send keys to emulate change
        subject_field = wp_page.subject_field
        subject_field.set("")
        subject_field.send_keys("a")
        subject_field.send_keys(:backspace)

        save_work_package!(false)
        toaster.expect_error("Subject can't be blank.")
      end
    end

    context "with subject set" do
      it "creates a basic work package" do
        description_field = wp_page.edit_field :description
        description_field.set_value description

        save_work_package!
        expect(page).to have_css(".op-work-package-tabs")

        subject_field.expect_state_text(subject)
        description_field = wp_page.edit_field :description
        description_field.expect_state_text(description)
      end

      it "can switch types and keep attributes" do
        wp_page.subject_field.set(subject)
        type_field.activate!
        type_field.openSelectField
        type_field.set_value type_bug.name

        save_work_package!

        wp_page.expect_attributes(subject:)
        wp_page.expect_attributes type: type_bug.name.upcase
      end

      context "custom fields" do
        let(:custom_field1) do
          create(
            :work_package_custom_field,
            field_format: "string",
            is_required: true,
            is_for_all: true
          )
        end
        let(:custom_field2) do
          create(
            :work_package_custom_field,
            field_format: "list",
            possible_values: %w(foo bar xyz),
            is_required: false,
            is_for_all: true
          )
        end
        let(:custom_fields) do
          [custom_field1, custom_field2]
        end
        let(:type_task) { create(:type_task, custom_fields:) }
        let(:project) do
          create(:project,
                 types:,
                 work_package_custom_fields: custom_fields)
        end

        it do
          custom_fields.map(&:id)
          cf1 = find(".#{custom_fields.first.attribute_name(:camel_case)} input")
          expect(cf1).not_to be_nil

          expect(page).to have_css(".#{custom_fields.last.attribute_name(:camel_case)} ng-select")

          cf = wp_page.edit_field custom_fields.last.attribute_name(:camel_case)
          cf.field_type = "create-autocompleter"
          cf.openSelectField
          cf.set_value "foo"
          save_work_package!(false)

          toaster.expect_error("#{custom_field1.name} can't be blank.")

          cf1.set "Custom field content"
          save_work_package!(true)

          wp_page.expect_attributes "customField#{custom_field1.id}" => "Custom field content",
                                    "customField#{custom_field2.id}" => "foo"
        end
      end
    end
  end

  context "project split screen" do
    let(:safeguard_selector) { ".work-packages--details-content.-create-mode" }
    let(:wp_page) { Pages::SplitWorkPackage.new(WorkPackage.new) }
    let(:wp_table) { Pages::WorkPackagesTable.new(project) }

    before do
      wp_table.visit!
    end

    it_behaves_like "work package creation workflow" do
      let(:create_method) { method(:create_work_package) }
    end

    it "allows to go to the full page through the toaster (Regression #37555)" do
      create_work_package(type_task)
      save_work_package!

      wp_page.expect_toast message: "Successful creation."
    end

    it "reloads the table and selects the new work package" do
      expect(page).to have_no_css(".wp--row")

      create_work_package(type_task)
      expect(page).to have_selector(safeguard_selector, wait: 10)

      wp_page.subject_field.set("new work package")
      save_work_package!
      wp_page.dismiss_toaster!

      expect(page).to have_css(".wp--row.-checked")

      # Editing the subject after creation
      # Fix for WP #23879
      new_wp = WorkPackage.last
      new_subject = "new subject"
      table_subject = wp_table.edit_field(new_wp, :subject)
      table_subject.activate!
      table_subject.set_value new_subject
      table_subject.submit_by_enter
      table_subject.expect_state_text new_subject

      wp_page.expect_toast(
        message: "Successful update."
      )

      new_wp.reload
      expect(new_wp.subject).to eq(new_subject)

      # Expect this to be synced
      details_subject = wp_table.edit_field(new_wp, :subject)
      details_subject.expect_state_text new_subject
    end
  end

  context "full screen" do
    let(:safeguard_selector) { ".work-package--new-state" }
    let(:existing_wp) { create(:work_package, type: type_bug, project:) }
    let(:wp_page) { Pages::FullWorkPackage.new(existing_wp) }

    before do
      wp_page.visit!
      wp_page.ensure_page_loaded
    end

    it "displays chosen date attribute for milestone type (#44701)" do
      click_create_work_package_button(type_milestone)

      date_field = wp_page.edit_field(:date)

      date_field.expect_value(I18n.t("js.label_no_date"))

      # Set date
      date_field.click_to_open_datepicker
      date = Time.zone.today.iso8601
      date_field.set_milestone_date date
      date_field.save!

      # Expect date to be displayed
      date_field.expect_value date
    end

    it_behaves_like "work package creation workflow" do
      let(:create_method) { method(:create_work_package) }
    end
  end

  context "global split screen" do
    let(:safeguard_selector) { ".work-packages--details-content.-create-mode" }
    let(:wp_page) { Pages::SplitWorkPackage.new(WorkPackage.new) }
    let(:wp_table) { Pages::WorkPackagesTable.new(nil) }

    before do
      wp_table.visit!
    end

    it_behaves_like "work package creation workflow" do
      let(:create_method) { method(:create_work_package_globally) }
    end

    it "can stop and re-create with correct selection (Regression #30216)" do
      create_work_package_globally(type_bug, project.name)

      click_on "Cancel"

      wp_page.click_create_wp_button type_bug
      expect(page).to have_no_css(".ng-value", text: project.name)

      project_field.openSelectField
      project_field.set_value project.name

      click_on "Cancel"
    end

    it "sets a default date that is readable (Regression #34291)" do
      create_work_package_globally(type_bug, project.name)

      date_field = wp_page.edit_field(:combinedDate)
      date_field.expect_value("no start date - no finish date")

      click_on "Cancel"
    end

    it "can save the work package with an assignee (Regression #32887)" do
      create_work_package_globally(type_task, project.name)
      expect(page).to have_selector(safeguard_selector, wait: 10)

      wp_page.subject_field.set("new work package")
      save_work_package!
      wp_page.dismiss_toaster!

      assignee_field.expect_state_text user.name
      wp = WorkPackage.last
      expect(wp.assigned_to).to eq user
    end

    it "resets the dates when opening the datepicker and cancelling (Regression #44152)" do
      create_work_package_globally(type_task, project.name)
      expect(page).to have_selector(safeguard_selector, wait: 10)

      # Open datepicker
      date_field = wp_page.edit_field(:combinedDate)
      date_field.click_to_open_datepicker

      # Select date
      start = (Time.zone.today - 1.day).iso8601
      date_field.set_start_date start

      due = (Time.zone.today + 1.day).iso8601
      date_field.set_due_date due

      # Cancel
      date_field.cancel_by_click
      date_field.expect_value "no start date - no finish date"
    end

    context "with a project without type_bug" do
      let!(:project_without_bug) do
        create(:project, name: "Unrelated project", types: [type_task])
      end

      it "does not show that value in the project drop down" do
        create_work_package_globally(type_bug, project.name)

        project_field.openSelectField

        expect(page).to have_css(".ng-dropdown-panel .ng-option", text: project.name)
        expect(page).to have_no_css(".ng-dropdown-panel .ng-option", text: project_without_bug.name)
      end
    end
  end

  context "as a user with no permissions" do
    let(:role) { create(:project_role, permissions: %i(view_work_packages)) }
    let(:user) { create(:user, member_with_roles: { project => role }) }
    let(:wp_page) { Pages::Page.new }

    let(:paths) do
      [
        new_work_packages_path,
        new_split_work_packages_path,
        new_project_work_packages_path(project),
        new_split_project_work_packages_path(project)
      ]
    end

    it "shows a 403 error on creation paths" do
      paths.each do |path|
        visit path
        wp_page.expect_toast(type: :error, message: I18n.t("api_v3.errors.code_403"))
      end
    end
  end

  context "as a user with add_work_packages permission, but not edit_work_packages permission (Regression 28580)" do
    let(:role) { create(:project_role, permissions: %i(view_work_packages add_work_packages)) }
    let(:user) { create(:user, member_with_roles: { project => role }) }
    let(:wp_page) { Pages::FullWorkPackageCreate.new }

    before do
      visit new_project_work_packages_path(project)
    end

    it "can create the work package, but not update it after saving" do
      type_field.activate!
      type_field.set_value type_bug.name
      # wait after the type change
      sleep(0.2)
      subject_field.update("new work package", save: true)

      wp_page.expect_and_dismiss_toaster(
        message: "Successful creation."
      )

      subject_field.expect_read_only
      subject_field.display_element.click
      subject_field.expect_inactive!
    end
  end

  context "an anonymous user is prompted to login" do
    let(:user) { create(:anonymous) }
    let(:wp_page) { Pages::Page.new }

    let(:paths) do
      [
        new_work_packages_path,
        new_split_work_packages_path,
        new_project_work_packages_path(project),
        new_split_project_work_packages_path(project)
      ]
    end

    it "shows a 403 error on creation paths" do
      paths.each do |path|
        visit path
        expect(wp_page.current_url).to match /#{signin_path}\?back_url=/
      end
    end
  end

  context "creating child work packages" do
    let!(:parent) do
      create(:work_package,
             project:,
             author: user,
             start_date: Date.today - 5.days,
             due_date: Date.today + 5.days)
    end
    let(:context_menu) { Components::WorkPackages::ContextMenu.new }
    let(:split_create_page) { Pages::SplitWorkPackageCreate.new(project:) }
    let(:permissions) { %i[view_work_packages add_work_packages edit_work_packages manage_subtasks] }
    let(:wp_page) { Pages::FullWorkPackage.new(parent) }
    let(:wp_page_create) { Pages::FullWorkPackageCreate.new(project:) }

    it "from within the table" do
      work_packages_page.visit_index

      context_menu.open_for(parent)
      context_menu.choose("Create new child")

      # The dates are taken over from the parent by default
      date_field = split_create_page.edit_field(:combinedDate)
      date_field.expect_value("#{parent.start_date} - #{parent.due_date}")

      date_field.click_to_open_datepicker
      date_field.update ["", parent.due_date]

      subject = split_create_page.edit_field(:subject)
      subject.set_value "Child"

      split_create_page.save!

      split_create_page.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_create"))

      split_create_page.expect_attributes(combinedDate: "no start date - #{parent.due_date.strftime('%m/%d/%Y')}")

      expect(split_create_page).to have_test_selector("op-wp-breadcrumb", text: "Parent:\n#{parent.subject}")
    end

    it "can navigate to the fullscreen page (Regression #49565)" do
      work_packages_page.visit_index

      context_menu.open_for(parent)
      context_menu.choose("Create new child")

      subject_field = split_create_page.edit_field(:subject)
      subject_field.set_value "My subtask"

      find(".work-packages-show-view-button").click

      expect(split_create_page).not_to have_alert_dialog
      subject_field = wp_page_create.edit_field(:subject)
      subject_field.expect_value "My subtask"
    end

    it "from the relations tab" do
      wp_page.visit_tab!("relations")

      click_button("Create new child")

      subject = EditField.new wp_page, :subject
      subject.set_value "Child"
      subject.submit_by_enter

      wp_page.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_create"))

      # Move to the newly created child
      wp_page.find("wp-children-query tbody.results-tbody tr").double_click

      wp_page.expect_attributes(combinedDate: "#{parent.start_date.strftime('%m/%d/%Y')} - #{parent.due_date.strftime('%m/%d/%Y')}")

      expect(wp_page).to have_test_selector("op-wp-breadcrumb", text: "Parent:\n#{parent.subject}")
    end
  end
end
