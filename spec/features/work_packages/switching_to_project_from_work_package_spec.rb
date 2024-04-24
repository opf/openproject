require "spec_helper"

RSpec.describe "Switching to project from work package", :js do
  let(:user) { create(:admin) }

  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }

  let(:wp_table) { Pages::WorkPackagesTable.new }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }

  before do
    login_as(user)
    work_package
  end

  it "allows to switch to the project the work package belongs to" do
    wp_table.visit!
    wp_table.expect_work_package_listed work_package

    # Open WP in global selection
    wp_table.open_full_screen_by_link work_package

    # Follow link to project
    expect(page).to have_css(".attributes-group.-project-context")
    link = find(".attributes-group.-project-context .project-context--switch-link")
    expect(link[:href]).to include(project_path(project.id))

    link.click
    # Redirection causes a trailing / on the path
    expect(page).to have_current_path("#{project_path(project.id)}/")
  end
end
