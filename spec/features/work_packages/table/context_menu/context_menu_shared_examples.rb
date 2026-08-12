# frozen_string_literal: true

require "spec_helper"

RSpec.shared_examples_for "provides a single WP context menu" do
  let(:open_context_menu) { raise "needs to be defined" }
  let(:destroy_modal) { Components::WorkPackages::DestroyModal.new }
  let(:time_logging_modal) { Components::TimeLoggingModal.new }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(work_package.project) }

  it "provides a context menu" do
    # Open detail pane
    open_context_menu.call
    menu.choose("Open details view")
    split_page = Pages::SplitWorkPackage.new(work_package, work_package.project)
    split_page.expect_attributes Subject: work_package.subject

    # Open full view
    open_context_menu.call
    menu.choose("Open fullscreen view")
    expect(page).to have_css(".work-packages--show-view .inline-edit--container.subject",
                             text: work_package.subject)

    # Open log time
    open_context_menu.call
    menu.choose("Log time")
    time_logging_modal.is_visible true

    # TODO: it seems like the modal is not properly loaded here? all methods seem to fail
    # time_logging_modal.has_hidden_work_package_field_for(work_package)
    # time_logging_modal.activity_input_disabled_because_work_package_missing? false
    time_logging_modal.cancel

    # Open Move
    open_context_menu.call
    menu.choose("Move to another project")
    expect(page).to have_css("h2", text: I18n.t(:button_move))
    expect(page).to have_css("a.work_package", text: "##{work_package.id}")

    # Open Duplicate
    open_context_menu.call
    menu.choose("Duplicate")
    # Split view open in duplicate state
    expect(page)
      .to have_css(".wp-new-top-row",
                   text: "#{work_package.status.name.capitalize}\n#{work_package.type.name.upcase}")
    expect(page).to have_field("wp-new-inline-edit--field-subject", with: work_package.subject)

    # Open Delete
    open_context_menu.call
    menu.choose("Delete")
    destroy_modal.expect_listed(work_package)
    destroy_modal.cancel_deletion

    # Open create new child
    open_context_menu.call
    menu.choose("Create new child")
    expect(page).to have_css(".inline-edit--container.subject input")
    expect(current_url).to match(/.*\/(create_new|details\/new)\?.*(&)*parent_id=#{work_package.id}/)

    find_by_id("work-packages--edit-actions-cancel").click
    expect(page).to have_no_css(".inline-edit--container.subject input")

    # Timeline actions only shown when open
    wp_timeline.expect_timeline!(open: false)

    open_context_menu.call
    menu.expect_no_options "Add predecessor", "Add successor", "Show relations"

    # Duplicate in another project
    open_context_menu.call
    menu.choose("Duplicate in another project")
    expect(page).to have_css("h2", text: I18n.t(:button_duplicate))
    expect(page).to have_css("a.work_package", text: "##{work_package.id}")
  end

  describe "creating work packages" do
    let!(:priority) { create(:issue_priority, is_default: true) }
    let!(:status) { create(:default_status) }

    it "can create a new child from the context menu (Regression #33329)" do
      open_context_menu.call
      menu.choose("Create new child")
      expect(page).to have_css(".inline-edit--container.subject input")
      expect(current_url).to match(/.*\/(create_new|details\/new)\?.*(&)*parent_id=#{work_package.id}/)

      split_view = Pages::SplitWorkPackageCreate.new project: work_package.project
      subject = split_view.edit_field(:subject)
      subject.set_value "Child task"
      # Wait a bit for the split view to be fully initialized
      sleep 1
      subject.submit_by_enter

      split_view.expect_and_dismiss_toaster message: "Successful creation."
      expect(page).to have_css('[data-test-selector="op-wp-breadcrumb"]', text: "Parent:\n#{work_package.subject}")
      wp = WorkPackage.last
      expect(wp.parent).to eq work_package
    end

    context "with semantic identifiers enabled",
            with_settings: { work_packages_identifier: "semantic" } do
      # The shared project is created classic-style (lowercase identifier), but
      # semantic mode requires the uppercase format. Rewrite it before any
      # example-scoped setup so work-package allocation and URL helpers both see
      # a valid semantic prefix. Specs that create their own project per example
      # should prefer the `:semantic` factory trait instead.
      around do |example|
        semantic_project_identifier = "PROJ#{project.id}".first(Projects::Identifier::SEMANTIC_IDENTIFIER_MAX_LENGTH)
        project.update_columns(identifier: semantic_project_identifier)
        example.run
      end

      it "uses numeric parent_id in the URL and sets the parent correctly" do
        expect(Setting::WorkPackageIdentifier.semantic?)
          .to be(true), "expected semantic mode to be active via with_settings metadata"

        work_package.allocate_and_register_semantic_id if work_package.identifier.blank?

        open_context_menu.call
        menu.choose("Create new child")
        expect(page).to have_css(".inline-edit--container.subject input")

        expect(current_url).to match(/parent_id=#{work_package.id}/)
        expect(current_url).not_to match(/parent_id=#{Regexp.escape(work_package.identifier)}/)

        split_view = Pages::SplitWorkPackageCreate.new project: work_package.project
        subject = split_view.edit_field(:subject)
        subject.set_value "Semantic child"
        expect(page).to have_field("wp-new-inline-edit--field-subject", with: "Semantic child", wait: 10)
        subject.submit_by_enter

        split_view.expect_and_dismiss_toaster message: "Successful creation."
        expect(page).to have_test_selector("op-wp-breadcrumb", text: "Parent:\n#{work_package.subject}")

        child = WorkPackage.last
        expect(child.parent).to eq work_package
      end
    end
  end
end
