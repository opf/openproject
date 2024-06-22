require "spec_helper"
require "support/pages/work_packages/abstract_work_package"

RSpec.describe "support for non-open version values in version custom field", :js, :with_cuprite do
  shared_let(:admin) { create(:admin) }
  let(:current_user) { admin }
  let(:wp_page) { Pages::FullWorkPackage.new work_package }
  let(:cf_edit_field) do
    field = wp_page.edit_field custom_field.attribute_name(:camel_case)
    field.field_type = "create-autocompleter"
    field
  end
  let(:work_package) { create(:work_package, project:, type:) }
  let!(:version_closed) { create(:version, project:, name: "Version Closed", status: "closed") }
  let!(:version_locked) { create(:version, project:, name: "Version Locked", status: "locked") }
  let!(:version_open) { create(:version, project:, name: "Version Open", status: "open") }

  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:role) { create(:project_role) }

  shared_let(:custom_field) do
    create(
      :version_wp_custom_field,
      name: "Affected version",
      multi_value: false,
      allow_non_open_versions: true,
      types: [type],
      projects: [project]
    )
  end

  before do
    login_as current_user
    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  it "is shown and allowed to be updated with open or non-open version" do
    expect(page).to have_text custom_field.name

    cf_edit_field.activate!
    expect(page).to have_text "Version Open"
    expect(page).to have_text "Version Locked"
    expect(page).to have_text "Version Closed"

    cf_edit_field.set_value "Version Locked"
    wp_page.expect_and_dismiss_toaster(message: "Successful update.")

    expect(page).to have_text custom_field.name
    expect(page).to have_no_text "Version Open"
    expect(page).to have_text "Version Locked"
    expect(page).to have_no_text "Version Closed"

    work_package.reload

    # only one value, so no array
    cvs = work_package
            .custom_value_for(custom_field)
            .typed_value
    expect(cvs).to eq version_locked

    # Let's check edit and both closed and open versions as well:
    cf_edit_field.activate!
    cf_edit_field.set_value "Version Closed"
    wp_page.expect_and_dismiss_toaster(message: "Successful update.")
    expect(page).to have_text "Version Closed"

    cf_edit_field.activate!
    cf_edit_field.set_value "Version Open"
    wp_page.expect_and_dismiss_toaster(message: "Successful update.")
    expect(page).to have_text "Version Open"

    work_package.reload

    cvs = work_package
            .custom_value_for(custom_field)
            .typed_value
    expect(cvs).to eq version_open
  end

  context "with multi-value version field" do
    shared_let(:custom_field) do
      create(
        :version_wp_custom_field,
        name: "Affected versions",
        multi_value: true,
        allow_non_open_versions: true,
        types: [type],
        projects: [project]
      )
    end

    it "is shown and allowed to be updated with open or non-open version" do
      expect(page).to have_text custom_field.name

      # First we set mix of open and non-open values
      cf_edit_field.activate!
      expect(page).to have_text "Version Open"
      expect(page).to have_text "Version Locked"
      expect(page).to have_text "Version Closed"

      cf_edit_field.set_value "Version Locked"
      cf_edit_field.set_value "Version Open"

      cf_edit_field.submit_by_dashboard
      wp_page.expect_and_dismiss_toaster(message: "Successful update.")

      expect(page).to have_text custom_field.name
      expect(page).to have_text "Version Open"
      expect(page).to have_text "Version Locked"
      expect(page).to have_no_text "Version Closed"

      work_package.reload

      cvs = work_package
              .custom_value_for(custom_field)
              .map(&:typed_value)
      expect(cvs).to contain_exactly(version_open, version_locked)

      # Update with a single non-open value
      cf_edit_field.activate!
      cf_edit_field.unset_value "Version Open", multi: true
      cf_edit_field.unset_value "Version Locked", multi: true
      cf_edit_field.set_value "Version Closed"

      cf_edit_field.submit_by_dashboard
      wp_page.expect_and_dismiss_toaster(message: "Successful update.")

      expect(page).to have_text "Version Closed"

      work_package.reload

      # only one value, so no array
      cvs = work_package
              .custom_value_for(custom_field)
              .typed_value

      expect(cvs).to eq version_closed
    end
  end

  context "with non-open values disabled" do
    shared_let(:custom_field) do
      create(
        :version_wp_custom_field,
        name: "Affected versions",
        multi_value: false, # this doesn't matter that much, it's the same for single and multi-values
        allow_non_open_versions: false,
        types: [type],
        projects: [project]
      )
    end

    it "is shown but non-open version are not shown as options" do
      expect(page).to have_text custom_field.name

      # We'll just check the options and nothing more, the rest is checked elsewhere
      cf_edit_field.activate!
      expect(page).to have_text "Version Open"
      expect(page).to have_no_text "Version Locked"
      expect(page).to have_no_text "Version Closed"
    end
  end
end
