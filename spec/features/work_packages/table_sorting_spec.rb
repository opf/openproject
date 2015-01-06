require 'spec_helper'
require 'features/work_packages/work_packages_page'

describe 'Select work package row', type: :feature do
  let(:user) { FactoryGirl.create(:admin) }
  let(:project) { FactoryGirl.create(:project) }
  let(:work_package_1) do
    FactoryGirl.create(:work_package, project: project)
  end
  let(:work_package_2) do
    FactoryGirl.create(:work_package, project: project)
  end
  let(:work_packages_page) { WorkPackagesPage.new(project) }

  let(:version_1) do
    FactoryGirl.create(:version, project: project,
                                 name: 'aaa_version')
  end
  let(:version_2) do
    FactoryGirl.create(:version, project: project,
                                 name: 'zzz_version')
  end

  before do
    allow(User).to receive(:current).and_return(user)

    work_package_1
    work_package_2

    work_packages_page.visit_index
  end

  include_context 'select2 helpers'
  include_context 'work package table helpers'

  after do
    ensure_wp_page_is_loaded
  end

  context 'sorting by version', js: true do
    before do
      work_package_1.update_attribute(:fixed_version_id, version_2.id)
      work_package_2.update_attribute(:fixed_version_id, version_1.id)
    end

    it 'sorts by version although version is not selected as a column' do
      remove_wp_table_column('Version')

      sort_wp_table_by('Version')

      expect_work_packages_to_be_in_order([work_package_1, work_package_2])
    end
  end
end
