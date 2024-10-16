require "spec_helper"

RSpec.describe "Switching types in work package table", :js do
  let(:user) { create(:admin) }

  describe "switching to required CF" do
    let(:cf_req_text) do
      create(
        :work_package_custom_field,
        field_format: "string",
        name: "Required CF",
        is_required: true,
        is_for_all: false
      )
    end
    let(:cf_text) do
      create(
        :work_package_custom_field,
        field_format: "string",
        is_required: false,
        is_for_all: false
      )
    end

    let(:type_task) { create(:type_task, custom_fields: [cf_text]) }
    let(:type_bug) { create(:type_bug, custom_fields: [cf_req_text]) }

    let(:project) do
      create(
        :project,
        types: [type_task, type_bug],
        work_package_custom_fields: [cf_text, cf_req_text]
      )
    end
    let(:work_package) do
      create(:work_package,
             subject: "Foobar",
             type: type_task,
             project:)
    end
    let(:wp_table) { Pages::WorkPackagesTable.new(project) }

    let(:query) do
      query = build(:query, user:, project:)
      query.column_names = ["id", "subject", "type", cf_text.column_name]

      query.save!
      query
    end

    # Using let to memoize the fields sometimes leads to invalid node reference errors in chrome 113.
    def type_field
      wp_table.edit_field(work_package, :type)
    end

    def text_field
      wp_table.edit_field(work_package, cf_text.attribute_name(:camel_case))
    end

    def req_text_field
      wp_table.edit_field(work_package, cf_req_text.attribute_name(:camel_case))
    end

    before do
      login_as(user)
      query
      project
      work_package

      wp_table.visit_query(query)
      wp_table.expect_work_package_listed(work_package)
    end

    it "switches the types correctly" do
      expect(text_field).to be_editable

      # Set non-required CF
      text_field.activate!
      text_field.set_value "Foobar"
      text_field.save!

      wp_table.expect_and_dismiss_toaster(
        message: "Successful update."
      )

      # Switch type
      type_field.activate!
      type_field.set_value type_bug.name

      wp_table.expect_and_dismiss_toaster(
        type: :error,
        message: "#{cf_req_text.name} can't be blank."
      )

      # Required CF requires activation
      req_text_field.activate!
      req_text_field.set_value "Required"
      req_text_field.save!

      wp_table.expect_and_dismiss_toaster(
        message: "Successful update."
      )

      expect { text_field.display_element }.to raise_error(Capybara::ElementNotFound)

      type_field.activate!
      type_field.set_value type_task.name

      wp_table.expect_and_dismiss_toaster(
        message: "Successful update."
      )

      expect(page).to have_no_css "#{req_text_field.selector} #{req_text_field.display_selector}"
      expect { req_text_field.display_element }.to raise_error(Capybara::ElementNotFound)
    end

    it "can switch back from an open required CF (Regression test #28099)" do
      # Switch type
      type_field.activate!
      type_field.set_value type_bug.name

      wp_table.expect_and_dismiss_toaster(
        type: :error,
        message: "#{cf_req_text.name} can't be blank."
      )

      # Required CF requires activation
      req_text_field.expect_active!

      # Now switch back to a type without the required CF
      type_field.activate!
      type_field.openSelectField
      type_field.set_value type_task.name

      wp_table.expect_and_dismiss_toaster(
        message: "Successful update."
      )
    end

    context "switching to single view" do
      let(:wp_split) { wp_table.open_split_view(work_package) }
      let(:type_field) { wp_split.edit_field(:type) }
      let(:text_field) { wp_split.edit_field(cf_text.attribute_name(:camel_case)) }
      let(:req_text_field) { wp_split.edit_field(cf_req_text.attribute_name(:camel_case)) }

      it "allows editing and cancelling the new required fields" do
        wp_split

        # Switch type
        type_field.activate!
        type_field.set_value type_bug.name

        wp_table.expect_and_dismiss_toaster(
          type: :error,
          message: "#{cf_req_text.name} can't be blank."
        )

        # Required CF requires activation
        req_text_field.expect_active!

        # Cancel edition now
        SeleniumHubWaiter.wait
        req_text_field.cancel_by_escape
        req_text_field.expect_state_text "-"

        # Set the value now
        req_text_field.update "foobar"

        wp_table.expect_and_dismiss_toaster(
          message: "Successful update."
        )

        req_text_field.expect_state_text "foobar"
      end
    end
  end

  describe "switching to required bool CF with default value" do
    let(:cf_req_bool) do
      create(
        :work_package_custom_field,
        field_format: "bool",
        is_required: true,
        default_value: false
      )
    end

    let(:type_task) { create(:type_task) }
    let(:type_bug) { create(:type_bug, custom_fields: [cf_req_bool]) }

    let(:project) do
      create(
        :project,
        types: [type_task, type_bug],
        work_package_custom_fields: [cf_req_bool]
      )
    end
    let(:work_package) do
      create(:work_package,
             subject: "Foobar",
             type: type_task,
             project:)
    end
    let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
    let(:type_field) { wp_page.edit_field :type }

    before do
      login_as user
      wp_page.visit!
      wp_page.ensure_page_loaded
    end

    it "can switch to the bug type without errors" do
      type_field.expect_state_text type_task.name.upcase
      type_field.update type_bug.name

      wp_page.expect_and_dismiss_toaster message: "Successful update."

      type_field.expect_state_text type_bug.name.upcase

      work_package.reload
      expect(work_package.type_id).to eq(type_bug.id)
      expect(work_package.send(cf_req_bool.attribute_getter)).to be(false)
    end
  end

  describe "switching to list CF" do
    let!(:wp_page) { Pages::FullWorkPackageCreate.new }
    let!(:type_with_cf) { create(:type_task, custom_fields: [custom_field]) }
    let!(:type) { create(:type_bug) }
    let(:permissions) { %i(view_work_packages add_work_packages) }
    let(:role) { create(:project_role, permissions:) }
    let(:user) do
      create(:user,
             member_with_roles: { project => role })
    end

    let(:custom_field) do
      create(
        :list_wp_custom_field,
        name: "Ingredients",
        multi_value: true,
        possible_values: ["ham", "onions", "pineapple", "mushrooms"]
      )
    end

    let!(:project) do
      create(
        :project,
        types: [type, type_with_cf],
        work_package_custom_fields: [custom_field]
      )
    end
    let!(:status) { create(:default_status) }
    let!(:workflow) do
      create(:workflow,
             type_id: type.id,
             old_status: status,
             new_status: create(:status),
             role:)
    end

    let!(:priority) { create(:priority, is_default: true) }

    let(:cf_edit_field) do
      field = wp_page.edit_field custom_field.attribute_name(:camel_case)
      field.field_type = "create-autocompleter"
      field
    end

    before do
      workflow
      login_as(user)

      visit new_project_work_packages_path(project.identifier, type: type.id)
      expect_angular_frontend_initialized
      SeleniumHubWaiter.wait
    end

    it "can switch to the type with CF list" do
      # Set subject
      subject = wp_page.edit_field :subject
      subject.set_value "My subject"

      # Switch type
      type_field = wp_page.edit_field :type
      type_field.activate!
      type_field.set_value type_with_cf.name

      # Scroll to element so it is fully visible
      scroll_to_element(cf_edit_field.field_container)

      cf_edit_field.openSelectField
      cf_edit_field.set_value "pineapple"
      cf_edit_field.set_value "mushrooms"

      wp_page.save!

      wp_page.expect_toast(
        message: "Successful creation."
      )

      new_wp = WorkPackage.last
      expect(new_wp.subject).to eq("My subject")
      expect(new_wp.type_id).to eq(type_with_cf.id)
      expect(new_wp.custom_value_for(custom_field.id).map(&:typed_value)).to match_array(%w(pineapple mushrooms))
    end
  end
end
