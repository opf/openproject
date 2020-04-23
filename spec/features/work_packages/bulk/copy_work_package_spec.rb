require 'spec_helper'
require 'features/page_objects/notification'

describe 'Copy work packages through Rails view', js: true do
  let(:dev_role) do
    FactoryBot.create :role,
                       permissions: %i[view_work_packages]
  end
  let(:mover_role) do
    FactoryBot.create :role,
                       permissions: %i[view_work_packages copy_work_packages move_work_packages manage_subtasks assign_versions add_work_packages]
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
  let!(:work_package2) {
    FactoryBot.create(:work_package,
                       author: dev,
                       project: project,
                       type: type)
  }

  let(:status) { work_package.status }
  let!(:version) { FactoryBot.create :version, project: project2 }
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
    wp_table.expect_work_package_listed work_package, work_package2

    # Select all work packages
    find('body').send_keys [:control, 'a']
  end

  describe 'copying work packages' do
    context 'with permission' do
      let(:current_user) { mover }

      before do
        wp_table.expect_work_package_count 2
        context_menu.open_for work_package
        context_menu.choose 'Bulk copy'

        expect(page).to have_selector('#new_project_id')
        select 'Target', from: 'new_project_id'

        sleep 1

        expect(page).to have_select('Project', selected: 'Target')
      end

      it 'sets the version on copy' do
        select version.name, from: 'version_id'
        click_on 'Copy and follow'

        wp_table.expect_work_package_count 2
        expect(page).to have_selector('#projects-menu', text: 'Target')

        # Should not move the sources
        work_package2.reload
        work_package.reload

        # Check project of last two created wps
        copied_wps = WorkPackage.last(2)
        expect(copied_wps.map(&:project_id).uniq).to eq([project2.id])
        expect(copied_wps.map(&:version_id).uniq).to eq([version.id])
      end

      describe 'copy and follow' do
        before do
          click_on 'Copy and follow'
        end

        it 'moves parent and child wp to a new project' do
          expect_angular_frontend_initialized
          wp_table.expect_work_package_count 2
          expect(page).to have_selector('#projects-menu', text: 'Target')

          # Should not move the sources
          work_package2.reload
          work_package.reload
          expect(work_package.project_id).to eq(project.id)
          expect(work_package2.project_id).to eq(project.id)

          # Check project of last two created wps
          copied_wps = WorkPackage.last(2)
          expect(copied_wps.map(&:project_id)).to eq([project2.id, project2.id])
        end

        context 'when the target project does not have the type' do
          let!(:project2) { FactoryBot.create(:project, name: 'Target', types: [type2]) }

          it 'does moves the work package and changes the type' do
            expect(page).to have_selector('.flash.error', text: "Failed to save 2 work package(s) on 2 selected:")
          end
        end
      end
    end

    context 'without permission' do
      let(:current_user) { dev }

      it 'does not allow to copy' do
        context_menu.open_for work_package
        context_menu.expect_no_options 'Bulk copy'
      end
    end
  end

  describe 'accessing the bulk copy from the card view' do
    before do
      display_representation.switch_to_card_layout
      loading_indicator_saveguard
    end

    context 'with permissions' do
      let(:current_user) { mover }

      it 'does allow to copy' do
        context_menu.open_for work_package
        context_menu.expect_options ['Bulk copy']
      end
    end

    context 'without permission' do
      let(:current_user) { dev }

      it 'does not allow to copy' do
        context_menu.open_for work_package
        context_menu.expect_no_options ['Bulk copy']
      end
    end
  end
end
