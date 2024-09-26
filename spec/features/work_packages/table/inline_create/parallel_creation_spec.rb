require "spec_helper"

RSpec.describe "Parallel work package creation spec", :js do
  let(:type) { project.types.first }

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

  let!(:project) { create(:project, public: true) }
  let!(:priority) { create(:priority, is_default: true) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  before do
    workflow
    login_as user
  end

  def new_work_package_in_both(subject, description)
    # Enable inline-create
    wp_table.click_inline_create
    subject_field = wp_table.edit_field(nil, :subject)
    subject_field.expect_active!
    subject_field.set_value subject

    # Create in split screen
    split = wp_table.create_wp_by_button type
    description_field = TextEditorField.new split, "description"
    description_field.expect_active!
    description_field.set_value description
  end

  it "with a new work package in split and inline create, both are saved" do
    # Expect table to be empty
    wp_table.visit!
    wp_table.expect_no_work_package_listed

    # Open split screen and inline create
    new_work_package_in_both "Some subject", "My description!"

    # Save in inline create
    expect(page).to have_css(".wp-inline-create-row")
    expect(page).to have_css(".wp--row", count: 1)

    subject_field = wp_table.edit_field(nil, :subject)
    subject_field.save!

    # There should be one row, and no open inline create row
    expect(page).to have_css(".wp--row", count: 1)
    expect(page).to have_no_css(".wp-inline-create-row")

    wp_table.expect_toast(
      message: "Successful creation."
    )
    wp_table.dismiss_toaster!

    # Get the last work package
    wp1 = WorkPackage.last
    expect(wp1.subject).to eq "Some subject"
    expect(wp1.description).to eq "My description!"

    wp_table.expect_work_package_listed wp1

    # Both are saved
    created_split = Pages::SplitWorkPackage.new wp1, project
    subject_field = created_split.edit_field :subject
    subject_field.expect_inactive!
    subject_field.expect_state_text "Some subject"

    # Open split screen and inline create
    new_work_package_in_both "New subject", "New description"

    # Inline create still open
    expect(page).to have_css(".wp-inline-create-row")

    # Save in split screen
    new_split = Pages::SplitWorkPackageCreate.new(project:)
    subject_field = new_split.edit_field :subject
    subject_field.expect_active!
    subject_field.expect_value "New subject"
    subject_field.save!

    wp_table.expect_toast(
      message: "Successful creation."
    )
    wp_table.dismiss_toaster!
    expect(page).to have_css(".wp--row", count: 2)
    expect(page).to have_no_css(".wp-inline-create-row")

    # Get the last work package
    wp2 = WorkPackage.last
    expect(wp2.subject).to eq "New subject"
    expect(wp2.description).to eq "New description"
  end
end
