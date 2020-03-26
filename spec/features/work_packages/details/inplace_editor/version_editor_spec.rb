require 'spec_helper'
require 'features/work_packages/details/inplace_editor/shared_examples'
require 'features/work_packages/shared_contexts'
require 'support/edit_fields/edit_field'
require 'features/work_packages/work_packages_page'

describe 'subject inplace editor', js: true, selenium: true do
  let(:project) { FactoryBot.create :project_with_types, name: 'Root', public: true }
  let(:subproject1) { FactoryBot.create :project_with_types, name: 'Child', parent: project }
  let(:subproject2) { FactoryBot.create :project_with_types, name: 'Aunt', parent: project }

  let!(:version) do
    FactoryBot.create(:version,
                      name: '1. First version',
                      status: 'open',
                      sharing: 'tree',
                      start_date: '2019-02-02',
                      effective_date: '2019-02-03',
                      project: project)
  end
  let!(:version2) do
    FactoryBot.create(:version,
                      status: 'open',
                      sharing: 'tree',
                      name: '2. Second version',
                      start_date: '2020-02-02',
                      effective_date: '2020-02-03',
                      project: subproject1)
  end
  let!(:version3) do
    FactoryBot.create(:version,
                      status: 'open',
                      sharing: 'tree',
                      start_date: nil,
                      effective_date: nil,
                      name: '3. Third version',
                      project: subproject2)
  end

  let(:property_name) { :version }
  let(:work_package) { FactoryBot.create :work_package, project: project }
  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %i[view_work_packages edit_work_packages manage_versions assign_versions]
  end
  let(:second_user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %i[view_work_packages edit_work_packages assign_versions]
  end
  let(:permissions) { %i[view_work_packages edit_work_packages assign_versions] }
  let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }

  context 'with manage permissions' do
    before do
      login_as(user)
    end

    it 'renders hierarchical versions' do
      work_package_page.visit!
      work_package_page.ensure_page_loaded

      field = work_package_page.work_package_field(:version)
      field.activate!

      expect(page).to have_selector('.ng-option-label', text: '-')
      expect(page).to have_selector('.ng-option-label', text: version3.name)
      expect(page).to have_selector('.ng-option-label', text: version2.name)
      expect(page).to have_selector('.ng-option-label', text: version.name)

      # Expect the order to be descending by version date
      labels = page.all('.ng-option-label').map { |el| el.text.strip }
      expect(labels).to eq ['-', version.name, version2.name, version3.name]

      page.find('.ng-option-label', text: version3.name).select_option
      field.expect_state_text(version3.name)
    end

    it 'allows creating versions from within the WP view' do
      work_package_page.visit!
      work_package_page.ensure_page_loaded

      field = work_package_page.work_package_field(:version)
      field.activate!

      field.set_new_value 'Super cool new release'
      field.expect_state_text 'Super cool new release'

      visit settings_versions_project_path(project)
      expect(page).to have_content 'Super cool new release'
    end
  end

  context 'without the permission to manage versions' do
    before do
      login_as(second_user)
    end

    it 'does not allow creating versions from within the WP view' do
      work_package_page.visit!
      work_package_page.ensure_page_loaded

      field = work_package_page.work_package_field(:version)
      field.activate!

      field.input_element.find('input').set 'Version that does not exist'
      expect(page).not_to have_selector('.ng-option', text: 'Create: Version that does not exist')
    end
  end
end
