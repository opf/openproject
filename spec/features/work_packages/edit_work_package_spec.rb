require "spec_helper"
require "features/page_objects/notification"

RSpec.describe "edit work package", :js do
  let(:dev_role) do
    create(:project_role,
           permissions: %i[view_work_packages
                           add_work_packages])
  end
  let(:dev) do
    create(:user,
           firstname: "Dev",
           lastname: "Guy",
           member_with_roles: { project => dev_role })
  end
  let(:manager_role) do
    create(:project_role,
           permissions: %i[view_work_packages
                           edit_work_packages
                           work_package_assigned])
  end
  let(:manager) do
    create(:admin,
           firstname: "Manager",
           lastname: "Guy",
           member_with_roles: { project => manager_role })
  end
  let(:placeholder_user) do
    create(:placeholder_user,
           member_with_roles: { project => manager_role })
  end

  let(:cf_all) do
    create(:work_package_custom_field, is_for_all: true, field_format: "text")
  end

  let(:cf_tp1) do
    create(:work_package_custom_field, is_for_all: true, field_format: "text")
  end

  let(:cf_tp2) do
    create(:work_package_custom_field, is_for_all: true, field_format: "text")
  end

  let(:type) { create(:type, custom_fields: [cf_all, cf_tp1]) }
  let(:type2) { create(:type, custom_fields: [cf_all, cf_tp2]) }
  let(:project) { create(:project, types: [type, type2]) }
  let(:work_package) do
    create(:work_package,
           :created_in_past,
           author: dev,
           project:,
           created_at: 5.days.ago,
           type:)
  end
  let(:status) { work_package.status }

  let(:new_subject) { "Some other subject" }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:priority2) { create(:priority) }
  let(:status2) { create(:status) }
  let(:workflow) do
    create(:workflow,
           type_id: type2.id,
           old_status: work_package.status,
           new_status: status2,
           role: manager_role)
  end
  let(:version) { create(:version, project:) }
  let(:category) { create(:category, project:) }

  let(:visit_before) { true }

  def visit!
    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  before do
    login_as(manager)

    manager
    dev
    priority2
    workflow
    status

    if visit_before
      visit!
    end
  end

  context "as an admin without roles" do
    let(:visit_before) { false }
    let(:work_package) { create(:work_package, project:, type: type2) }
    let(:admin) { create(:admin) }

    it "can still use the manager role" do
      # A role must still exist
      workflow
      login_as admin
      visit!

      wp_page.update_attributes status: status2.name
      wp_page.expect_attributes status: status2.name

      wp_page.expect_activity_message("Status changed from #{status.name} to #{status2.name}")
    end
  end

  it "allows updating and seeing the results" do
    wp_page.update_attributes subject: "a new subject",
                              type: type2.name,
                              combinedDate: ["2013-03-04", "2013-03-20"],
                              responsible: manager.name,
                              assignee: manager.name,
                              estimatedTime: "10",
                              remainingTime: "7",
                              priority: priority2.name,
                              version: version.name,
                              category: category.name,
                              status: status2.name,
                              description: "a new description"

    wp_page.expect_attributes type: type2.name.upcase,
                              responsible: manager.name,
                              assignee: manager.name,
                              combinedDate: "03/04/2013 - 03/20/2013",
                              estimatedTime: "10h",
                              remainingTime: "7h",
                              percentageDone: "30%",
                              subject: "a new subject",
                              description: "a new description",
                              priority: priority2.name,
                              status: status2.name,
                              version: version.name,
                              category: category.name

    wp_page.expect_activity_message("Status changed from #{status.name} to #{status2.name}")
  end

  it "correctly assigns and un-assigns users" do
    wp_page.update_attributes assignee: manager.name
    wp_page.expect_attributes assignee: manager.name
    wp_page.expect_activity_message("Assignee set to #{manager.name}")

    field = wp_page.edit_field :assignee
    field.unset_value

    wp_page.expect_attributes assignee: "-"

    wp_page.visit!

    # Another (empty) journal should exist now
    expect(page).to have_css(".op-user-activity--user-name",
                             text: work_package.journals.last.user.name,
                             wait: 10,
                             count: 2)

    wp_page.expect_attributes assignee: "-"

    work_package.reload
    expect(work_package.assigned_to).to be_nil
  end

  it "allows selecting placeholder users for assignee and responsible" do
    wp_page.update_attributes assignee: placeholder_user.name,
                              responsible: placeholder_user.name

    wp_page.expect_attributes assignee: placeholder_user.name,
                              responsible: placeholder_user.name

    wp_page.expect_activity_message("Assignee set to #{placeholder_user.name}")
    wp_page.expect_activity_message("Accountable set to #{placeholder_user.name}")
  end

  context "switching to custom field with required CF" do
    let(:custom_field) do
      create(
        :work_package_custom_field,
        field_format: "string",
        default_value: nil,
        is_required: true,
        is_for_all: true
      )
    end
    let!(:type2) { create(:type, custom_fields: [custom_field]) }

    it "shows the required field when switching" do
      type_field = wp_page.edit_field(:type)

      type_field.activate!
      type_field.set_value type2.name

      wp_page.expect_toast message: "#{custom_field.name} can't be blank.",
                           type: "error"

      cf_field = wp_page.edit_field(custom_field.attribute_name(:camel_case))
      cf_field.expect_active!
      cf_field.expect_value("")
    end
  end

  it "allows the user to add a comment to a work package" do
    wp_page.ensure_page_loaded

    wp_page.trigger_edit_comment
    wp_page.update_comment "hallo welt"

    wp_page.save_comment

    wp_page.expect_toast(message: "The comment was successfully added.")
    wp_page.expect_comment text: "hallo welt"
  end

  it "updates the presented custom fields based on the selected type" do
    wp_page.ensure_page_loaded

    wp_page.expect_attributes "customField#{cf_all.id}" => "",
                              "customField#{cf_tp1.id}" => ""
    wp_page.expect_attribute_hidden "customField#{cf_tp2.id}"

    wp_page.update_attributes "customField#{cf_all.id}" => "bird is the word",
                              "type" => type2.name

    wp_page.expect_attributes "customField#{cf_all.id}" => "bird is the word",
                              "customField#{cf_tp2.id}" => ""
    wp_page.expect_attribute_hidden "customField#{cf_tp1.id}"
  end

  it "shows an error if a subject is entered which is too long" do
    too_long = ("Too long. Can you feel it? " * 10).strip

    wp_page.ensure_page_loaded
    field = wp_page.work_package_field(:subject)
    field.update(too_long, expect_failure: true)

    wp_page.expect_toast message: "Subject is too long (maximum is 255 characters)",
                         type: "error"
  end

  context "submitting" do
    let(:subject_field) { wp_page.edit_field(:subject) }

    before do
      subject_field.activate!
      subject_field.set_value "My new subject!"
    end

    it "submits the edit mode when pressing enter" do
      subject_field.input_element.send_keys(:return)

      wp_page.expect_toast(message: "Successful update")
      subject_field.expect_inactive!
      subject_field.expect_state_text "My new subject!"
    end

    it "does not close the edit mode when changing the focus" do
      page.find("body").click

      subject_field.expect_active!
      wp_page.expect_no_toaster(type: :success, message: "Successful update", wait: 1)
    end
  end
end
