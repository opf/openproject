require 'spec_helper'

describe 'Project context switching spec', js: true do
  let(:user) { FactoryBot.create :admin }

  let(:project) { FactoryBot.create(:project) }
  let(:work_package) { FactoryBot.create(:work_package, project: project) }

  let(:wp_table) { Pages::WorkPackagesTable.new  }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }

  before do
    login_as(user)
    work_package
  end

  it 'allows to switch context' do
    wp_table.visit!
    wp_table.expect_work_package_listed work_package

    # Open WP in global selection
    wp_table.open_full_screen_by_link work_package

    # Follow link to project context
    expect(page).to have_selector('.attributes-group.-project-context')
    link = find('.attributes-group.-project-context .project-context--switch-link')
    expect(link[:href]).to include(project_work_package_path(project.id, work_package.id))

    link.click
    wp_page.ensure_page_loaded
    expect(page).to have_no_selector('.attributes-group.-project-context')
  end
end
