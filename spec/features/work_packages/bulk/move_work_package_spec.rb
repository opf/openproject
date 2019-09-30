require 'spec_helper'
require 'features/page_objects/notification'

describe 'Moving a work package through Rails view', js: true do
  let(:dev_role) do
    FactoryBot.create :role,
                       permissions: %i[view_work_packages add_work_packages]
  end
  let(:mover_role) do
    FactoryBot.create :role,
                       permissions: %i[view_work_packages move_work_packages manage_subtasks add_work_packages]
  end
  let(:dev) do
    FactoryBot.create :user,
                       firstname: 'Dev',
                       lastname: 'Guy',
                       member_in_project: project,
                       member_through_role: dev_role
  end
  let(:mover) do
    FactoryBot.create :admin,
                       firstname: 'Manager',
                       lastname: 'Guy',
                       member_in_project: project,
                       member_through_role: mover_role
  end

  let(:type) { FactoryBot.create :type, name: 'Bug' }
  let(:type2) { FactoryBot.create :type, name: 'Risk' }

  let!(:project) { FactoryBot.create(:project, name: 'Source', types: [type, type2]) }
  let!(:project2) { FactoryBot.create(:project, name: 'Target', types: [type, type2]) }

  let!(:work_package) {
    FactoryBot.create(:work_package,
                       author: dev,
                       project: project,
                       type: type)
  }
  let!(:child_wp) {
    FactoryBot.create(:work_package,
                       author: dev,
                       parent: work_package,
                       project: project,
                       type: type)
  }

  let(:status) { work_package.status }
  let!(:status2) { FactoryBot.create :default_status }
  let!(:workflow) do
    FactoryBot.create :workflow,
                       type_id: type2.id,
                       old_status: work_package.status,
                       new_status: status2,
                       role: mover_role
  end

  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }
  let(:display_representation) { ::Components::WorkPackages::DisplayRepresentation.new }

  before do
    login_as current_user
    wp_table.visit!
    expect_angular_frontend_initialized
    wp_table.expect_work_package_listed work_package, child_wp
  end

  describe 'moving a work package and its children' do
    context 'with permission' do
      let(:current_user) { mover }

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
        let!(:project2) { FactoryBot.create(:project, name: 'Target', types: [type2]) }

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

  describe 'accessing the bulk move from the card view' do
    before do
      display_representation.switch_to_card_layout
      loading_indicator_saveguard
      find('body').send_keys [:control, 'a']
    end

    context 'with permissions' do
      let(:current_user) { mover }

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
