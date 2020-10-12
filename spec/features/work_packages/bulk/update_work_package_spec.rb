require 'spec_helper'
require 'features/page_objects/notification'

describe 'Bulk update work packages through Rails view', js: true do
  let(:dev_role) do
    FactoryBot.create :role,
                       permissions: %i[view_work_packages]
  end
  let(:mover_role) do
    FactoryBot.create :role,
                       permissions: %i[view_work_packages copy_work_packages move_work_packages manage_subtasks add_work_packages]
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

  let!(:project) { FactoryBot.create(:project, name: 'Source', types: [type]) }

  let!(:status) { FactoryBot.create :status }

  let!(:work_package) {
    FactoryBot.create(:work_package,
                       author: dev,
                       status: status,
                       project: project,
                       type: type)
  }
  let!(:work_package2) {
    FactoryBot.create(:work_package,
                       author: dev,
                       status: status,
                       project: project,
                       type: type)
  }

  let!(:status2) { FactoryBot.create :default_status }
  let!(:workflow) do
    FactoryBot.create :workflow,
                       type_id: type.id,
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
        context_menu.open_for work_package
        context_menu.choose 'Bulk edit'

        # On work packages edit page
        expect(page).to have_selector('#work_package_status_id')
        select status2.name, from: 'work_package_status_id'
      end

      it 'sets two statuses' do
        click_on 'Submit'

        expect_angular_frontend_initialized
        wp_table.expect_work_package_count 2

        # Should update the status
        work_package2.reload
        work_package.reload
        expect(work_package.status_id).to eq(status2.id)
        expect(work_package2.status_id).to eq(status2.id)
      end

      context 'when making an error in the form' do
        it 'does not update the work packages' do
          fill_in 'work_package_start_date', with: '123'
          click_on 'Submit'

          expect(page).to have_selector('.notification-box', text: I18n.t('work_packages.bulk.could_not_be_saved'))
          expect(page).to have_selector('.notification-box', text: work_package.id)
          expect(page).to have_selector('.notification-box', text: work_package2.id)

          # Should not update the status
          work_package2.reload
          work_package.reload
          expect(work_package.status_id).to eq(status.id)
          expect(work_package2.status_id).to eq(status.id)
        end
      end
    end

    context 'without permission' do
      let(:current_user) { dev }

      it 'does not allow to copy' do
        context_menu.open_for work_package
        context_menu.expect_no_options 'Bulk edit'
      end
    end
  end

  describe 'accessing the bulk edit from the card view' do
    before do
      display_representation.switch_to_card_layout
      loading_indicator_saveguard
    end

    context 'with permissions' do
      let(:current_user) { mover }

      it 'does allow to edit' do
        context_menu.open_for work_package
        context_menu.expect_options ['Bulk edit']
      end
    end

    context 'without permission' do
      let(:current_user) { dev }

      it 'does not allow to edit' do
        context_menu.open_for work_package
        context_menu.expect_no_options ['Bulk edit']
      end
    end
  end
end
