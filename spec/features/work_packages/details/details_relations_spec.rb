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
      expect(page).to have_selector('.wp-relations-hierarchy-subject a', text: parent.subject.to_s)
    end
  end

  describe 'create parent relationship' do
    include_context 'typeahead helpers'
    let!(:parent) { FactoryGirl.create(:work_package, project: project) }
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
        find('.wp-inline-create--add-link', text: I18n.t('js.relation_buttons.add_parent')).click

        # Locate the create row container
        container = find('.wp-relations--parent-form')

        # Enter the query and select the child
        typeahead = container.find(".wp-relations--autocomplete")
        select_typeahead(typeahead, query: parent.subject)

        container.find('.wp-create-relation--save').click

        expect(page).to have_selector('.wp-relations-hierarchy-subject',
                                      text: parent.subject,
                                      wait: 10)
      end
    end
  end

  describe 'create child relationship' do
    let!(:child) { FactoryGirl.create(:work_package, project: project) }
    include_context 'typeahead helpers'

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

      it 'activates the add existing child form' do
        find('.wp-inline-create--add-link',
             text: I18n.t('js.relation_buttons.add_existing_child')).click

        # Locate the create row container
        container = find('.wp-relations--child-form')

        # Enter the query and select the child
        typeahead = container.find(".wp-relations--autocomplete")
        select_typeahead(typeahead, query: child.id)

        container.find('.wp-create-relation--save').click

        expect(page).to have_selector('.wp-relations-hierarchy-subject a',
                                      text: child.subject)
      end
    end
  end
end
