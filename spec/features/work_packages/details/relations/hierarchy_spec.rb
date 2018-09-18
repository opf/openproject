require 'spec_helper'

describe 'Work package relations tab', js: true, selenium: true do
  include_context 'ui-autocomplete helpers'

  let(:user) { FactoryBot.create :admin }

  let(:project) { FactoryBot.create(:project) }
  let(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:work_packages_page) { ::Pages::SplitWorkPackage.new(work_package) }
  let(:full_wp) { ::Pages::FullWorkPackage.new(work_package) }
  let(:relations) { ::Components::WorkPackages::Relations.new(work_package) }

  let(:visit) { true }

  before do
    login_as user

    if visit
      visit_relations
    end
  end

  def visit_relations
    work_packages_page.visit_tab!('relations')
    work_packages_page.expect_subject
    loading_indicator_saveguard
  end

  describe 'as admin' do
    let!(:parent) { FactoryBot.create(:work_package, project: project) }
    let!(:child) { FactoryBot.create(:work_package, project: project) }
    let!(:child2) { FactoryBot.create(:work_package, project: project, subject: 'Something new') }

    it 'allows to manage hierarchy' do
      # Shows link parent link
      expect(page).to have_selector('#hierarchy--add-parent')
      find('.work-packages--details .wp-inline-create--add-link',
           text: I18n.t('js.relation_buttons.add_parent')).click

      # Add parent
      relations.add_parent(parent.id, parent.subject)

      ##
      # Add child #1
      find('.work-packages--details .wp-inline-create--add-link',
           text: I18n.t('js.relation_buttons.add_existing_child')).click

      relations.add_existing_child(child)

      ##
      # Add child #2
      find('.work-packages--details .wp-inline-create--add-link',
           text: I18n.t('js.relation_buttons.add_existing_child')).click

      relations.add_existing_child(child2)
    end

    describe 'inline create' do
      let!(:status) { FactoryBot.create(:status, is_default: true) }
      let!(:priority) { FactoryBot.create(:priority, is_default: true) }
      let(:type_bug) { FactoryBot.create(:type_bug) }
      let!(:project) do
        FactoryBot.create(:project, types: [type_bug])
      end

      it 'can inline-create children' do
        relations.inline_create_child 'my new child'
        table = relations.children_table

        table.expect_work_package_subject 'my new child'
        work_package.reload
        expect(work_package.children.count).to eq(1)
      end
    end
  end

  describe 'relation group-by toggler' do
    let(:project) { FactoryBot.create :project, types: [type_1, type_2] }
    let(:type_1) { FactoryBot.create :type }
    let(:type_2) { FactoryBot.create :type }

    let(:to_1) { FactoryBot.create(:work_package, type: type_1, project: project) }
    let(:to_2) { FactoryBot.create(:work_package, type: type_2, project: project) }

    let!(:relation_1) do
      FactoryBot.create :relation,
                        from: work_package,
                        to: to_1,
                        relation_type: Relation::TYPE_FOLLOWS
    end
    let!(:relation_2) do
      FactoryBot.create :relation,
                        from: work_package,
                        to: to_2,
                        relation_type: Relation::TYPE_RELATES
    end

    let(:toggle_btn_selector) { '#wp-relation-group-by-toggle' }
    let(:visit) { false }

    before do
      visit_relations

      work_packages_page.visit_tab!('relations')
      work_packages_page.expect_subject
      loading_indicator_saveguard
    end

    describe 'with limited permissions' do
      let(:permissions) { %i(view_work_packages) }
      let(:user_role) do
        FactoryBot.create :role, permissions: permissions
      end

      let(:user) do
        FactoryBot.create :user,
                          member_in_project: project,
                          member_through_role: user_role
      end

      context 'as view-only user, with parent set' do
        let(:parent) { FactoryBot.create(:work_package, project: project) }
        let(:work_package) { FactoryBot.create(:work_package, parent: parent, project: project) }

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
        let!(:parent) { FactoryBot.create(:work_package, project: project) }
        let!(:child) { FactoryBot.create(:work_package, project: project) }

        it 'should be able to link parent and children' do
          # Shows link parent link
          expect(page).to have_selector('#hierarchy--add-parent')
          find('.work-packages--details .wp-inline-create--add-link',
               text: I18n.t('js.relation_buttons.add_parent')).click

          # Add parent
          relations.add_parent(parent.id, parent.subject)

          ##
          # Add child
          find('.work-packages--details .wp-inline-create--add-link',
               text: I18n.t('js.relation_buttons.add_existing_child')).click

          relations.add_existing_child(child)

          # Remove parent
          relations.remove_parent(parent.subject)

          # Remove child
          relations.remove_child(child)
        end
      end
    end
  end
end
