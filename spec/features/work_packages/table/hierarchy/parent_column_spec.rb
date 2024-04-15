require "spec_helper"

RSpec.describe "Work Package table parent column", :js do
  let(:user) { create(:admin) }
  let!(:parent) { create(:work_package, project:) }
  let!(:child) { create(:work_package, project:, parent:) }
  let!(:other_wp) { create(:work_package, project:) }
  let!(:query) do
    query = build(:query, user:, project:)
    query.column_names = ["subject", "parent"]
    query.filters.clear
    query.show_hierarchies = false

    query.save!
    query
  end
  let(:project) { create(:project) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  before do
    login_as(user)
  end

  it "shows parent columns correctly (Regression #26951)" do
    wp_table.visit_query query
    wp_table.expect_work_package_listed(parent, child)

    # Hierarchy mode is enabled by default
    page.within(".wp-row-#{parent.id}") do
      expect(page).to have_css("td.parent", text: "-")
    end

    page.within(".wp-row-#{child.id}") do
      expect(page).to have_css("td.parent", text: "##{parent.id}")
    end
  end

  it "can edit the parent work package (Regression #43647)" do
    wp_table.visit_query query
    wp_table.expect_work_package_listed(parent, child)

    parent_field = wp_table.edit_field(child, :parent)
    parent_field.update other_wp.subject

    wp_table.expect_and_dismiss_toaster message: "Successful update."

    child.reload
    expect(child.parent).to eq other_wp
  end
end
