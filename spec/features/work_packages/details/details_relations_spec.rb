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
      %w(parent children relates duplicates
         duplicated blocks blocked precedes follows).each do |rel|
        within ".relation.#{rel}" do
          find(".#{rel}-toggle-link").click
          expect(page).to have_selector('.content', text: 'No relation exists')
        end
      end
    end
  end

  describe 'with parent' do
    let(:parent) { FactoryGirl.create(:work_package) }
    let(:work_package) { FactoryGirl.create(:work_package, parent: parent) }

    it 'shows the parent relationship expanded' do
      expect(page).to have_selector('.parent .work_package',
                                    text: "##{parent.id} #{parent.type}: #{parent.subject}")
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

    context 'with insufficient permissions' do
      let(:permissions) { %i(view_work_packages edit_work_packages) }

      it 'does not allow editing the parent' do
        within '.relation.parent' do
          # Expand parent
          find('.parent-toggle-link').click

          expect(page).to have_no_selector('.choice--select')
          expect(page).to have_selector('.content', text: I18n.t('js.relations.empty'))

        end
      end
    end

    context 'with permissions' do
      let(:permissions) { %i(view_work_packages manage_subtasks) }

      it 'shows the parent relationship expanded' do
        within '.relation.parent' do
          # Expand parent
          find('.parent-toggle-link').click

          form = find('.choice--select')
          ui_select_choose(form, parent.subject)

          click_button 'Change parent'

          expect(page).to have_selector('.parent .work_package',
                                        text: "##{parent.id} #{parent.type}: #{parent.subject}")
        end
      end
    end
  end
end
