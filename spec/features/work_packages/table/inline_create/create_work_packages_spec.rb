require "spec_helper"

RSpec.describe "inline create work package", :js do
  let(:type) { create(:type) }
  let(:types) { [type] }

  let(:permissions) { %i(view_work_packages add_work_packages edit_work_packages) }
  let(:role) { create(:project_role, permissions:) }
  let(:user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:status) { create(:default_status) }
  let(:workflow) do
    create(:workflow,
           type_id: type.id,
           old_status: status,
           new_status: create(:status),
           role:)
  end

  let!(:project) { create(:project, public: true, types:) }
  let!(:existing_wp) { create(:work_package, project:) }
  let!(:priority) { create(:priority, is_default: true) }
  let(:filters) { Components::WorkPackages::Filters.new }

  before do
    workflow
    login_as user
  end

  shared_examples "inline create work package" do
    context "when user may create work packages" do
      it "allows to create work packages" do
        wp_table.expect_work_package_listed(existing_wp)

        wp_table.click_inline_create
        expect(page).to have_css(".wp--row", count: 2)
        expect(page).to have_css(".wp-inline-create-row")
        expect(page).to have_focus_on("#wp-new-inline-edit--field-subject")

        # Expect subject to be activated
        subject_field = wp_table.edit_field(nil, :subject)
        subject_field.expect_active!
        subject_field.set_value "Some subject"
        subject_field.save!

        # Callback for adjustments
        callback.call

        wp_table.expect_toast(
          message: "Successful creation."
        )

        # Expect new create row to exist
        expect(page).to have_css(".wp--row", count: 2)
        expect(page).to have_button(exact_text: "Create new work package")

        wp_table.click_inline_create

        subject_field = wp_table.edit_field(nil, :subject)
        subject_field.expect_active!
        subject_field.set_value "Another subject"
        subject_field.save!

        # Callback for adjustments
        callback.call

        expect(page).to have_css(".wp--row .subject", text: "Some subject")
        expect(page).to have_css(".wp--row .subject", text: "Another subject")

        # safeguards
        wp_table.dismiss_toaster!
        wp_table.expect_no_toaster(
          message: "Successful update."
        )

        # Expect no inline create open
        expect(page).to have_no_css(".wp-inline-create-row")
      end
    end

    context "when user may not create work packages" do
      let(:permissions) { [:view_work_packages] }

      it "renders the work package, but no create row" do
        wp_table.expect_work_package_listed(existing_wp)
        expect(page).to have_no_button(exact_text: "Create new work package")
      end
    end

    context "when having filtered by custom field and switching to that type" do
      let(:cf_list) do
        create(:list_wp_custom_field, is_for_all: true, is_filter: true)
      end
      let(:cf_accessor_frontend) { cf_list.attribute_name(:camel_case) }
      let(:types) { [type, cf_type] }
      let(:type) { create(:type_standard) }
      let(:cf_type) { create(:type, custom_fields: [cf_list]) }
      let(:columns) { Components::WorkPackages::Columns.new }

      it "applies the filter value for the custom field" do
        wp_table.visit!
        filters.open
        filters.add_filter_by cf_list.name, "is (OR)", cf_list.custom_options.second.name, cf_accessor_frontend

        sleep(0.3)

        columns.open_modal
        columns.add(cf_list.name, save_changes: true)

        wp_table.click_inline_create

        callback.call

        type_field = wp_table.edit_field(nil, :type)
        type_field.activate!
        type_field.set_select_field_value cf_type.name

        wp_table.expect_toast(
          type: :error,
          message: "Subject can't be blank."
        )

        subject_field = wp_table.edit_field(nil, :subject)
        subject_field.expect_active!
        subject_field.set_value "Some subject"
        subject_field.save!

        wp_table.expect_toast(
          message: "Successful creation."
        )

        created_wp = WorkPackage.last

        cf_field = wp_table.edit_field(created_wp, cf_list.attribute_name(:camel_case))
        cf_field.expect_text(cf_list.custom_options.second.name)
      end
    end
  end

  describe "global create" do
    let(:wp_table) { Pages::WorkPackagesTable.new }

    before do
      wp_table.visit!
    end

    it_behaves_like "inline create work package" do
      let(:callback) do
        -> {
          # Set project which will also select the type (first one in the selected project)
          project_field = wp_table.edit_field(nil, :project)
          project_field.expect_active!

          project_field.openSelectField
          project_field.set_value project.name
        }
      end
    end
  end

  describe "project context create" do
    let(:wp_table) { Pages::WorkPackagesTable.new(project) }

    before do
      wp_table.visit!
    end

    it_behaves_like "inline create work package" do
      let(:callback) do
        -> {}
      end
    end

    context "when user has permissions in other project" do
      let(:permissions) { [:view_work_packages] }

      let(:project2) { create(:project) }
      let(:role2) do
        create(:project_role,
               permissions: %i[view_work_packages
                               add_work_packages])
      end
      let!(:membership) do
        create(:member,
               user:,
               project: project2,
               roles: [role2])
      end

      it "renders the work packages, but no create" do
        wp_table.expect_work_package_listed(existing_wp)
        expect(page).to have_no_button(exact_text: "Create new work package")
        expect(page).to have_css(".add-work-package[disabled]")
      end
    end
  end
end
