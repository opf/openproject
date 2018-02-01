require 'spec_helper'

describe 'Work Package table parent column', js: true do
  let(:user) { FactoryGirl.create :admin }
  let(:project) { FactoryGirl.create(:project) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  before do
    login_as(user)
  end


  let!(:parent) { FactoryGirl.create(:work_package, project: project) }
  let!(:child) { FactoryGirl.create(:work_package, project: project, parent: parent) }

  let!(:query) do
    query              = FactoryGirl.build(:query, user: user, project: project)
    query.column_names = ['subject', 'parent']
    query.filters.clear
    query.show_hierarchies = false

    query.save!
    query
  end

  it 'shows parent columns correctly (Regression #26951)' do
    wp_table.visit_query query
    wp_table.expect_work_package_listed(parent, child)

    # Hierarchy mode is enabled by default
    page.within(".wp-row-#{parent.id}") do
      expect(page).to have_selector('td.parent', text: '-')
    end

    page.within(".wp-row-#{child.id}") do
      expect(page).to have_selector('td.parent', text: "##{parent.id}")
    end
  end
end
