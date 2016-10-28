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
    loading_indicator_saveguard
    work_packages_page.expect_subject
  end

  def add_hierarchy(container, query, expected_text)
    # Locate the create row container
    container = find(container)

    # Enter the query and select the child
    typeahead = container.find(".wp-relations--autocomplete")
    select_typeahead(typeahead, query: query)

    container.find('.wp-create-relation--save').click

    expect(page).to have_selector('.wp-relations-hierarchy-subject',
                                  text: expected_text,
                                  wait: 10)
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
end
