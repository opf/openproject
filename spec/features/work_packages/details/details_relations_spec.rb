require 'spec_helper'

describe 'Work package relations tab', js: true, selenium: true do
  let(:user) { FactoryGirl.create :admin }

  let(:project) { FactoryGirl.create :project }
  let(:work_package) { FactoryGirl.create(:work_package, project: project) }
  let(:work_packages_page) { ::Pages::SplitWorkPackage.new(work_package) }

  before do
    login_as user

    work_packages_page.visit_tab!('relations')
    loading_indicator_saveguard
    work_packages_page.expect_subject
  end

  describe 'no relations' do
    it 'shows empty relation tabs' do
      expect(page).to have_selector('.wp-relations-create')
      expect(page).to have_selector('.wp-relations-hierarchy-section')
    end
  end

  describe 'with parent' do
    let(:parent) { FactoryGirl.create(:work_package) }
    let(:work_package) { FactoryGirl.create(:work_package, parent: parent) }

    it 'shows the parent in hierarchy section' do
      expect(page).to have_selector('.wp-relations-hierarchy-subject a',
                                    text: "#{parent.subject}")
    end
  end

  describe 'create parent relationship' do
    let(:parent) { FactoryGirl.create(:work_package, project: project) }
    include_context 'ui-select helpers'

    let(:user_role) do
      FactoryGirl.create :role, permissions: permissions
    end

    let(:user) do
      FactoryGirl.create :user,
                         member_in_project: project,
                         member_through_role: user_role
    end

    context 'with permissions' do
      let(:permissions) { %i(view_work_packages manage_subtasks) }

      it 'activates the change parent form' do

          find('.wp-inline-create--add-link').click
          find('.inplace-edit--select').click

          input = find(:css, ".ui-select-search")
          input.set(parent.id)

          sleep(2)

          input.send_keys [:down, :return]

          save_button = find('.wp-relations--save a')
          save_button.click

          expect(page).to have_selector('.wp-relations-hierarchy-subject a',
                                             text: "#{parent.subject}")
      end
    end
  end
end
