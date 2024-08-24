require "spec_helper"

RSpec.describe "Subproject filters", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:parent) { create(:project) }
  shared_let(:archived) { create(:project, :archived, parent:, name: "archived project") }
  shared_let(:non_archived) { create(:project, parent:) }
  shared_let(:work_package) { create(:work_package, project: parent) }

  let(:wp_table) { Pages::WorkPackagesTable.new(parent) }
  let(:filters) { Components::WorkPackages::Filters.new }
  let(:user) { create(:admin) }

  before do
    login_as(user)
    work_package
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package)
  end

  # Tests for regression #54278
  it "does not allow to select archived subprojects" do
    # Open filter menu
    filters.expect_filter_count(1)
    filters.open

    filters.add_filter("Including subproject")

    dropdown = search_autocomplete(page.find("op-project-autocompleter"),
                                   query: "archive",
                                   results_selector: ".ng-dropdown-panel-items")

    expect(dropdown).to have_no_text "archived project"
  end
end
