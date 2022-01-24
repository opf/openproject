require 'spec_helper'
require 'features/page_objects/notification'

# rubocop:disable RSpec/MultipleMemoizedHelpers
describe 'Moving a work package through Rails view', js: true do
  let(:dev_role) do
    create :role,
                      permissions: %i[view_work_packages add_work_packages]
  end
  let(:mover_role) do
    create :role,
                      permissions: %i[view_work_packages move_work_packages manage_subtasks add_work_packages]
  end
  let(:dev) do
    create :user,
                      firstname: 'Dev',
                      lastname: 'Guy',
                      member_in_project: project,
                      member_through_role: dev_role
  end
  let(:mover) do
    create :admin,
                      firstname: 'Manager',
                      lastname: 'Guy',
                      member_in_project: project,
                      member_through_role: mover_role
  end

  let(:type) { create :type, name: 'Bug' }
  let(:type2) { create :type, name: 'Risk' }

  let!(:project) { create(:project, name: 'Source', types: [type, type2]) }
  let!(:project2) { create(:project, name: 'Target', types: [type, type2]) }

  let(:work_package) do
    create(:work_package,
                      author: dev,
                      project: project,
                      type: type,
                      status: status)
  end
  let(:work_package2) do
    create(:work_package,
                      author: dev,
                      project: project,
                      type: type,
                      status: work_package2_status)
  end
  let(:status) { create(:status) }
  let(:work_package2_status) { status }

  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }
  let(:display_representation) { ::Components::WorkPackages::DisplayRepresentation.new }
  let(:current_user) { mover }
  let(:work_packages) { [work_package, work_package2] }

  before do
    work_packages
    login_as current_user
    wp_table.visit!
    expect_angular_frontend_initialized
  end

  describe 'moving a work package and its children' do
    let(:work_packages) { [work_package, child_wp] }
    let(:child_wp) do
      create(:work_package,
                        author: dev,
                        parent: work_package,
                        project: project,
                        type: type,
                        status: status)
    end

    context 'with permission' do
      before do
        expect(child_wp.project_id).to eq(project.id)

        context_menu.open_for work_package
        context_menu.choose 'Change project'

        # On work packages move page
        expect(page).to have_selector('#new_project_id')
        select 'Target', from: 'new_project_id'
        click_on 'Move and follow'
      end

      it 'moves parent and child wp to a new project' do
        expect_angular_frontend_initialized
        expect(page).to have_selector('.inline-edit--container.subject', text: work_package.subject, wait: 10)
        expect(page).to have_selector('#projects-menu', text: 'Target')

        # Should move its children
        child_wp.reload
        expect(child_wp.project_id).to eq(project2.id)
      end

      context 'when the target project does not have the type' do
        let!(:project2) { create(:project, name: 'Target', types: [type2]) }

        it 'does moves the work package and changes the type' do
          expect_angular_frontend_initialized
          expect(page).to have_selector('.inline-edit--container.subject', text: work_package.subject, wait: 10)
          expect(page).to have_selector('#projects-menu', text: 'Target')

          # Should NOT have moved
          child_wp.reload
          work_package.reload
          expect(work_package.project_id).to eq(project2.id)
          expect(work_package.type_id).to eq(type2.id)
          expect(child_wp.project_id).to eq(project2.id)
          expect(child_wp.type_id).to eq(type2.id)
        end
      end
    end

    context 'without permission' do
      let(:current_user) { dev }

      it 'does not allow to move' do
        context_menu.open_for work_package
        context_menu.expect_no_options 'Change project'
      end
    end
  end

  describe 'moving an unmovable (e.g. readonly status) and a movable work package', with_ee: %i[readonly_work_packages] do
    let(:work_packages) { [work_package, work_package2] }
    let(:work_package2_status) { create(:status, is_readonly: true) }

    before do
      loading_indicator_saveguard
      # Select all work packages
      find('body').send_keys [:control, 'a']

      context_menu.open_for work_package2
      context_menu.choose 'Bulk change of project'

      # On work packages move page
      select project2.name, from: 'new_project_id'
      click_on 'Move and follow'
    end

    it 'displays an error message explaining which work package could not be moved and why' do
      expect(page)
        .to have_selector('.flash.error',
                          text: I18n.t('work_packages.bulk.could_not_be_saved'))

      expect(page)
        .to have_selector(
          '.flash.error',
          text: "#{work_package2.id}: Project #{I18n.t('activerecord.errors.messages.error_readonly')}"
        )

      expect(page)
        .to have_selector('.flash.error',
                          text: I18n.t('work_packages.bulk.x_out_of_y_could_be_saved',
                                       failing: 1,
                                       total: 2,
                                       success: 1))

      expect(work_package.reload.project_id).to eq(project2.id)
      expect(work_package2.reload.project_id).to eq(project.id)
    end
  end

  describe 'accessing the bulk move from the card view' do
    before do
      display_representation.switch_to_card_layout
      loading_indicator_saveguard
      find('body').send_keys [:control, 'a']
    end

    context 'with permissions' do
      it 'does allow to move' do
        context_menu.open_for work_package
        context_menu.expect_options ['Bulk change of project']
      end
    end

    context 'without permission' do
      let(:current_user) { dev }

      it 'does not allow to move' do
        context_menu.open_for work_package
        context_menu.expect_no_options ['Bulk change of project']
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
