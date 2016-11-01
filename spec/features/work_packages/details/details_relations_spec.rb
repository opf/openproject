require 'spec_helper'

describe 'Work package relations tab', js: true, selenium: true do
  include_context 'typeahead helpers'

  let(:user) { FactoryGirl.create :admin }

  let(:project) { FactoryGirl.create :project }
  let(:work_package) { FactoryGirl.create(:work_package, project: project) }
  let(:work_packages_page) { ::Pages::SplitWorkPackage.new(work_package) }

  before do
    login_as user

    work_packages_page.visit_tab!('relations')
    work_packages_page.expect_subject
    loading_indicator_saveguard
  end

  def add_hierarchy(container, query, expected_text)
    # Locate the create row container
    container = find(container)

    # Enter the query and select the child
    typeahead = container.find(".wp-relations--autocomplete")
    select_typeahead(typeahead, query: query, select_text: expected_text)

    container.find('.wp-create-relation--save').click

    expect(page).to have_selector('.wp-relations-hierarchy-subject',
                                  text: expected_text,
                                  wait: 10)
  end

  def remove_hierarchy(selector, removed_text)
    expect(page).to have_selector(selector, text: removed_text)
    container = find(selector)
    container.hover

    container.find('.wp-relation--remove').click
    expect(page).to have_no_selector(selector, text: removed_text, wait: 10)
  end

  describe 'as admin' do
     let!(:parent) { FactoryGirl.create(:work_package, project: project) }
     let!(:child) { FactoryGirl.create(:work_package, project: project) }
     let!(:child2) { FactoryGirl.create(:work_package, project: project, subject: 'Something new') }

    it 'allows to mange hierarchy' do
      # Shows link parent link
      expect(page).to have_selector('#hierarchy--add-parent')
      find('.wp-inline-create--add-link',
           text: I18n.t('js.relation_buttons.add_parent')).click

      # Add parent
      add_hierarchy('.wp-relations--parent-form', parent.id, parent.subject)

      ##
      # Add child #1
      find('.wp-inline-create--add-link',
           text: I18n.t('js.relation_buttons.add_existing_child')).click

      add_hierarchy('.wp-relations--child-form', child.id, child.subject)

      ##
      # Add child #2
      find('.wp-inline-create--add-link',
           text: I18n.t('js.relation_buttons.add_existing_child')).click

      add_hierarchy('.wp-relations--child-form', child2.subject, child2.subject)
    end
  end

  describe 'with limited permissions' do
    let(:permissions) { %i(view_work_packages) }
    let(:user_role) do
      FactoryGirl.create :role, permissions: permissions
    end

    let(:user) do
      FactoryGirl.create :user,
                         member_in_project: project,
                         member_through_role: user_role
    end

    context 'as view-only user, with parent set' do
      let(:parent) { FactoryGirl.create(:work_package, project: project) }
      let(:work_package) { FactoryGirl.create(:work_package, parent: parent, project: project) }

      it 'shows no links to create relations' do
        # No create buttons should exist
        expect(page).to have_no_selector('.wp-relations-create-button')

        # Test for add relation
        expect(page).to have_no_selector('#relation--add-relation')

        # Test for add parent
        expect(page).to have_no_selector('#hierarchy--add-parent')

        # Test for add children
        expect(page).to have_no_selector('#hierarchy--add-exisiting-child')
        expect(page).to have_no_selector('#hierarchy--add-new-child')

        # But it should show the linked parent
        expect(page).to have_selector('.wp-relations-hierarchy-subject', text: parent.subject)
      end
    end

    context 'with manage_subtasks permissions' do
      let(:permissions) { %i(view_work_packages manage_subtasks) }
      let!(:parent) { FactoryGirl.create(:work_package, project: project) }
      let!(:child) { FactoryGirl.create(:work_package, project: project) }

      it 'should be able to link parent and children' do
        # Shows link parent link
        expect(page).to have_selector('#hierarchy--add-parent')
        find('.wp-inline-create--add-link',
             text: I18n.t('js.relation_buttons.add_parent')).click

        # Add parent
        add_hierarchy('.wp-relations--parent-form', parent.id, parent.subject)

        ##
        # Add child
        find('.wp-inline-create--add-link',
             text: I18n.t('js.relation_buttons.add_existing_child')).click

        add_hierarchy('.wp-relations--child-form', child.id, child.subject)

        # Remove parent
        remove_hierarchy('.relation-row.parent', parent.subject)

        # Remove child
        remove_hierarchy('.relation-row.child', child.subject)
      end
    end

    context 'with add_work_packages permission' do
      let(:permissions) { %i(view_work_packages add_work_packages manage_subtasks) }
      it 'should contain link to create new child work packages' do
        find('#hierarchy--add-new-child').click
        expect(page).to have_selector('h2', text: "Child of #{work_package.type} ##{work_package.id}")
        find('#work-packages--edit-actions-cancel').click

        # Ensure wp table loads fine
        loading_indicator_saveguard
        table = Pages::WorkPackagesTable.new(project)
        table.expect_work_package_listed(work_package)
      end
    end

    context 'with relations permissions' do
      it 'should allow to create relations' do
      end
    end
  end
end
