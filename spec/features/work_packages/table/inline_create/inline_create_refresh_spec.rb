require "spec_helper"

RSpec.describe "Refreshing in inline-create row", :flaky, :js do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }

  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:columns) { Components::WorkPackages::Columns.new }

  let!(:query) do
    query              = build(:query, user:, project:)
    query.column_names = ["subject", "category"]
    query.filters.clear

    query.save!
    query
  end

  before do
    login_as user
    wp_table.visit_query(query)
  end

  it "correctly updates the set of active columns" do
    expect(page).to have_css(".wp--row", count: 0)

    wp_table.click_inline_create
    expect(page).to have_css(".wp--row", count: 1)

    expect(page).to have_css(".wp-inline-create-row")
    expect(page).to have_css(".wp-inline-create-row .wp-table--cell-td.subject")
    expect(page).to have_css(".wp-inline-create-row .wp-table--cell-td.category")

    columns.add "% Complete"
    expect(page).to have_css(".wp-inline-create-row .wp-table--cell-td.wp-table--cell-td.percentageDone")
  end
end
