require 'spec_helper'
require 'features/work_packages/details/inplace_editor/shared_examples'
require 'features/work_packages/shared_contexts'
require 'support/work_packages/work_package_field'
require 'features/work_packages/work_packages_page'

describe 'subject inplace editor', js: true, selenium: true do
  let(:project) { FactoryGirl.create :project_with_types, name: 'Root', is_public: true }
  let(:subproject1) { FactoryGirl.create :project_with_types, name: 'Child', parent: project }
  let(:subproject2) { FactoryGirl.create :project_with_types, name: 'Aunt', parent: project }

  let!(:version) {
    FactoryGirl.create(:version,
                       status: 'open',
                       sharing: 'tree',
                       project: project)
  }
  let!(:version2) {
    FactoryGirl.create(:version,
                       status: 'open',
                       sharing: 'tree',
                       project: subproject1)
  }
  let!(:version3) {
    FactoryGirl.create(:version,
                       status: 'open',
                       sharing: 'tree',
                       project: subproject2)
  }

  let(:property_name) { :version }
  let!(:work_package) { FactoryGirl.create :work_package, project: project }
  let(:user) { FactoryGirl.create :admin }
  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:field) { WorkPackageField.new page, property_name }

  before do
    login_as(user)
    work_packages_page.visit_index(work_package)
    within '.panel-toggler' do
      find('a', text: 'Show all attributes').click
    end
    field.activate_edition
  end

  it 'renders hierarchical versions' do
    expect(page).to have_selector("#{field.field_selector} select")

    options = page.all("#{field.field_selector} select option")
    expect(options.map(&:text)).to eq(['-', version3.name, version2.name, version.name])

    options[1].select_option
    field.submit_by_click

    field.expect_state_text(version3.name)

  end
end
