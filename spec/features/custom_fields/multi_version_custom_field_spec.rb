require "spec_helper"
require "support/pages/work_packages/abstract_work_package"

RSpec.describe "multi version custom field", :js do
  shared_let(:admin) { create(:admin) }
  let(:current_user) { admin }
  let(:wp_page) { Pages::FullWorkPackage.new work_package }
  let(:cf_edit_field) do
    field = wp_page.edit_field custom_field.attribute_name(:camel_case)
    field.field_type = "create-autocompleter"
    field
  end
  let(:work_package) { create(:work_package, project:, type:) }
  let!(:version_old) { create(:version, project:, name: "Version Old") }
  let!(:version_current) { create(:version, project:, name: "Version Current") }
  let!(:version_future) { create(:version, project:, name: "Version Future") }

  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:role) { create(:project_role) }

  shared_let(:custom_field) do
    create(
      :version_wp_custom_field,
      name: "Fix version",
      multi_value: true,
      types: [type],
      projects: [project]
    )
  end

  before do
    login_as current_user
    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  it "is shown and allowed to be updated" do
    expect(page).to have_text custom_field.name

    cf_edit_field.activate!
    cf_edit_field.set_value "Version Old"
    cf_edit_field.set_value "Version Current"
    cf_edit_field.set_value "Version Future"

    cf_edit_field.submit_by_dashboard

    expect(page).to have_text custom_field.name
    expect(page).to have_text "Version Old"
    expect(page).to have_text "Version Current"
    expect(page).to have_text "Version Future"

    wp_page.expect_and_dismiss_toaster(message: "Successful update.")

    work_package.reload
    cvs = work_package
            .custom_value_for(custom_field)
            .map(&:typed_value)

    expect(cvs).to contain_exactly(version_old, version_current, version_future)

    cf_edit_field.activate!
    cf_edit_field.unset_value "Version Current", multi: true
    cf_edit_field.unset_value "Version Future", multi: true
    cf_edit_field.submit_by_dashboard

    wp_page.expect_and_dismiss_toaster(message: "Successful update.")

    expect(page).to have_text "Version Old"
    expect(page).to have_no_text "Version Current"
    expect(page).to have_no_text "Version Future"

    work_package.reload

    # only one value, so no array
    cvs = work_package
            .custom_value_for(custom_field)
            .typed_value

    expect(cvs).to eq version_old
  end

  context "with existing version values" do
    let(:work_package) do
      wp = build(:work_package, project:, type:)

      wp.custom_field_values = {
        custom_field.id => [version_old.id.to_s, version_current.id.to_s]
      }

      wp.save
      wp
    end

    it "is shown and allowed to be updated" do
      expect(page).to have_text custom_field.name
      expect(page).to have_text "Version Old"
      expect(page).to have_text "Version Current"

      page.find(".inline-edit--display-field", text: "Version Old").click

      cf_edit_field.unset_value "Version Old", multi: true
      cf_edit_field.set_value "Version Future"

      click_on "Fix version: Save"
      wp_page.expect_and_dismiss_toaster(message: "Successful update.")
      # .customField<ID> above is required to ignore Assignee and Accountable which are not interesting for us.
      expect(page).to have_css(".customField#{custom_field.id} .custom-option", count: 2)

      expect(page).to have_text custom_field.name
      expect(page).to have_text "Version Current"
      expect(page).to have_text "Version Future"
      expect(page).to have_no_text "Version Old"
    end
  end
end
