require 'spec_helper'
require 'features/work_packages/details/inplace_editor/shared_examples'
require 'features/work_packages/shared_contexts'
require 'support/work_packages/work_package_field'
require 'features/work_packages/work_packages_page'

describe 'subject inplace editor', js: true, selenium: true do
  let(:project) { FactoryBot.create :project_with_types, name: 'Root', is_public: true }
  let(:subproject1) { FactoryBot.create :project_with_types, name: 'Child', parent: project }
  let(:subproject2) { FactoryBot.create :project_with_types, name: 'Aunt', parent: project }

  let!(:version) {
    FactoryBot.create(:version,
                       status: 'open',
                       sharing: 'tree',
                       project: project)
  }
  let!(:version2) {
    FactoryBot.create(:version,
                       status: 'open',
                       sharing: 'tree',
                       project: subproject1)
  }
  let!(:version3) {
    FactoryBot.create(:version,
                       status: 'open',
                       sharing: 'tree',
                       project: subproject2)
  }

  let(:property_name) { :version }
  let(:work_package) { FactoryBot.create :work_package, project: project }
  let(:user) { FactoryBot.create :admin }
  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }

  before do
    login_as(user)
  end

  it 'renders hierarchical versions' do
    work_package_page.visit!
    work_package_page.ensure_page_loaded

    field = work_package_page.work_package_field(:version)
    field.activate!

    options = field.all(".ng-option-label")

    expect(options.map(&:text)).to eq(['-', version3.name, version2.name, version.name])

    options[1].select_option
    field.expect_state_text(version3.name)
  end
end
