require 'spec_helper'
require 'features/work_packages/details/inplace_editor/shared_examples'
require 'features/work_packages/shared_contexts'
require 'support/work_packages/work_package_field'
require 'features/work_packages/work_packages_page'

describe 'subject inplace editor', js: true, selenium: true do
  let(:project) { FactoryBot.create :project_with_types, name: 'Root', is_public: true }
  let(:subproject1) { FactoryBot.create :project_with_types, name: 'Child', parent: project }
  let(:subproject2) { FactoryBot.create :project_with_types, name: 'Aunt', parent: project }

  let!(:version) do
    FactoryBot.create(:version,
                      status: 'open',
                      sharing: 'tree',
                      project: project)
  end
  let!(:version2) do
    FactoryBot.create(:version,
                      status: 'open',
                      sharing: 'tree',
                      project: subproject1)
  end
  let!(:version3) do
    FactoryBot.create(:version,
                      status: 'open',
                      sharing: 'tree',
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

      visit settings_project_path(project, tab: 'versions')
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
