# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Inline editing work packages", :js do
  let(:manager_permissions) { %i[view_work_packages edit_work_packages] }
  let(:manager_role) do
    create(:project_role, permissions: manager_permissions)
  end
  let(:manager_projects) { { project => manager_role } }
  let(:manager) do
    create(:user,
           firstname: "Manager",
           lastname: "Guy",
           member_with_roles: manager_projects)
  end
  let(:type) { create(:type) }
  let(:status1) { create(:status) }
  let(:status2) { create(:status) }

  let(:project) { create(:project, name: "Test Project", types: [type]) }
  let!(:work_package) do
    create(:work_package,
           project:,
           type:,
           status: status1,
           subject: "Foobar")
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let(:workflow) do
    create(:workflow,
           type_id: type.id,
           old_status: status1,
           new_status: status2,
           role: manager_role)
  end
  let(:version) { create(:version, project:) }
  let(:category) { create(:category, project:) }

  before do
    login_as(manager)
  end

  context "simple work package" do
    before do
      workflow

      wp_table.visit!
      wp_table.expect_work_package_listed(work_package)
    end

    it "allows updating and seeing the results" do
      subject_field = wp_table.edit_field(work_package, :subject)
      subject_field.expect_text("Foobar")

      subject_field.activate!

      subject_field.set_value("New subject!")

      expect(WorkPackages::UpdateService).to receive(:new).and_call_original
      subject_field.save!
      subject_field.expect_text("New subject!")

      wp_table.expect_toast(
        message: "Successful update."
      )

      work_package.reload
      expect(work_package.subject).to eq("New subject!")
    end

    it "allows to subsequently edit multiple fields" do
      subject_field = wp_table.edit_field(work_package, :subject)
      status_field  = wp_table.edit_field(work_package, :status)

      subject_field.activate!
      subject_field.set_value("Other subject!")
      subject_field.save!

      wp_table.expect_and_dismiss_toaster(message: "Successful update")

      status_field.activate!
      status_field.set_value(status2.name)

      subject_field.expect_inactive!
      status_field.expect_inactive!

      subject_field.expect_text("Other subject!")
      status_field.expect_text(status2.name)

      wp_table.expect_and_dismiss_toaster(message: "Successful update")

      work_package.reload
      expect(work_package.subject).to eq("Other subject!")
      expect(work_package.status.id).to eq(status2.id)
    end

    it "provides error handling" do
      subject_field = wp_table.edit_field(work_package, :subject)
      subject_field.expect_text("Foobar")

      subject_field.activate!

      subject_field.set_value("")
      subject_field.expect_invalid

      subject_field.save!

      wp_table.expect_and_dismiss_toaster(type: :error, message: "Subject can't be blank.")

      expect(work_package.reload.subject).to eq "Foobar"
    end
  end

  context "custom field" do
    let!(:custom_fields) do
      fields = [
        create(
          :work_package_custom_field,
          field_format: "list",
          possible_values: %w(foo bar xyz),
          is_required: false,
          is_for_all: false,
          types: [type],
          projects: [project]
        ),
        create(
          :work_package_custom_field,
          field_format: "string",
          is_required: false,
          is_for_all: false,
          types: [type],
          projects: [project]
        )
      ]

      fields
    end
    let(:type) { create(:type_task) }
    let(:project) { create(:project, types: [type]) }
    let!(:work_package) do
      create(:work_package,
             subject: "Foobar",
             status: status1,
             type:,
             project:)
    end

    before do
      workflow

      custom_fields.each do |custom_field|
        custom_field.update_attribute(:is_required, true)
      end

      wp_table.visit!
      wp_table.expect_work_package_listed(work_package)
    end

    it "opens required custom fields when not set" do
      subject_field = wp_table.edit_field(work_package, :subject)
      subject_field.expect_text("Foobar")

      subject_field.activate!
      subject_field.set_value("New subject!")
      subject_field.save!

      # Should raise two errors
      cf_list_name = custom_fields.first.name
      cf_text_name = custom_fields.last.name
      wp_table.expect_toast(
        type: :error,
        message: "#{cf_list_name} can't be blank.\n#{cf_text_name} can't be blank."
      )

      expect(page).to have_css("th a", text: cf_list_name.upcase)
      expect(page).to have_css("th a", text: cf_text_name.upcase)
      expect(wp_table.row(work_package)).to have_css(".wp-table--cell-container.-error", count: 2)

      cf_text = wp_table.edit_field(work_package, custom_fields.last.attribute_name(:camel_case))
      cf_text.update("my custom text", expect_failure: true)

      cf_list = wp_table.edit_field(work_package, custom_fields.first.attribute_name(:camel_case))
      cf_list.field_type = "create-autocompleter"
      cf_list.openSelectField
      cf_list.set_value("bar")

      cf_text.expect_inactive!
      cf_list.expect_inactive!

      wp_table.expect_toast(
        message: "Successful update."
      )

      work_package.reload
      expect(work_package.send(custom_fields.first.attribute_getter)).to eq("bar")
      expect(work_package.send(custom_fields.last.attribute_getter)).to eq("my custom text")

      # Saveguard to let the background update complete
      wp_table.visit!
      wp_table.expect_work_package_listed(work_package)
    end
  end

  context "when editing the project field with workspace types" do
    let!(:portfolio) { create(:portfolio, name: "Test Portfolio") }
    let!(:program) { create(:program, name: "Test Program") }
    let(:manager_permissions) { %i[view_work_packages edit_work_packages move_work_packages] }
    let(:manager_projects) do
      {
        project => manager_role,
        portfolio => manager_role,
        program => manager_role
      }
    end
    let(:query) do
      create(:public_query,
             user: manager,
             project: work_package.project,
             column_names: %w[subject project])
    end

    before do
      wp_table.visit_query query
      wp_table.expect_work_package_listed(work_package)
    end

    it "displays workspace type badges for portfolios and programs in the project column" do
      project_field = wp_table.edit_field(work_package, :project)
      project_field.activate!

      # Search for portfolio and verify badge
      project_field.search_for("Test Portfolio")
      project_field.expect_option(
        "Test Portfolio",
        workspace_badge: "Portfolio"
      )

      # Search for program and verify badge
      project_field.clear_search
      project_field.search_for("Test Program")
      project_field.expect_option(
        "Test Program",
        workspace_badge: "Program"
      )

      # Search for regular project and verify there is no badge
      project_field.clear_search
      project_field.search_for("Project")
      project_field.expect_option("Test Project", workspace_badge: false)
    end
  end
end
