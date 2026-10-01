# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Work Package table child relations",
               :js do
  shared_let(:user) { create(:admin) }

  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }

  shared_let(:query) do
    query              = build(:query, user:, project:)
    query.column_names = ["subject"]
    query.filters.clear

    query.save!
    query
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:relations) { Components::WorkPackages::Relations.new(relations) }
  let(:columns) { Components::WorkPackages::Columns.new }

  shared_let(:parent) { create(:work_package, subject: "Parent", project:, type:, author: user) }
  shared_let(:child) { create(:work_package, subject: "Child", parent:, project:, type:, author: user) }

  before do
    login_as(user)
  end

  it "displays expandable relation columns for the children of a work package" do
    # Now visiting the query for category
    wp_table.visit_query(query)
    wp_table.expect_work_package_listed(parent)

    columns.add("Children")

    parent_row = wp_table.row(parent)
    child_row = wp_table.row(child)

    # Expect count for parent to be one
    expect(parent_row).to have_css(".relationChild .wp-table--relation-count", text: "1")

    # Expect count for child to be not rendered
    expect(child_row).to have_no_css(".relationChild .wp-table--relation-count")

    # Expand column
    parent_row.find(".relationChild .wp-table--relation-indicator").click
    expect(page).to have_css(".__relations-expanded-from-#{parent.id}", count: 1)

    related_row = page.first(".__relations-expanded-from-#{parent.id}")
    expect(related_row).to have_css("td.wp-table--relation-cell-td", text: "Child")

    # Collapse
    parent_row.find(".relationChild .wp-table--relation-indicator").click
    expect(page).to have_no_css(".__relations-expanded-from-#{parent.id}")
  end
end
