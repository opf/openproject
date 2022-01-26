require 'spec_helper'
require 'features/page_objects/notification'

# rubocop:disable RSpec/MultipleMemoizedHelpers
describe 'Bulk update work packages through Rails view', js: true do
  let(:dev_role) do
    create :role,
                      permissions: %i[view_work_packages]
  end
  let(:mover_role) do
    create :role,
                      permissions: %i[view_work_packages copy_work_packages move_work_packages manage_subtasks add_work_packages]
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

  let!(:project) { create(:project, name: 'Source', types: [type]) }

  let!(:status) { create :status }
  let(:work_package2_status) { status }

  let!(:work_package) do
    create(:work_package,
                      author: dev,
                      status: status,
                      project: project,
                      type: type)
  end
  let!(:work_package2) do
    create(:work_package,
                      author: dev,
                      status: work_package2_status,
                      project: project,
                      type: type)
  end

  let!(:status2) { create :default_status }
  let!(:workflow) do
    create :workflow,
                      type_id: type.id,
                      old_status: work_package.status,
                      new_status: status2,
                      role: mover_role
  end

  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }
  let(:display_representation) { ::Components::WorkPackages::DisplayRepresentation.new }
  let(:notes) { ::Components::WysiwygEditor.new }

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
        notes.set_markdown('The typed note')
      end

      it 'sets status and leaves a note' do
        click_on 'Submit'

        expect_angular_frontend_initialized
        wp_table.expect_work_package_count 2

        # Should update the status
        expect([work_package.reload.status_id, work_package2.reload.status_id].uniq)
          .to eq([status2.id])

        expect([work_package.journals.last.notes, work_package2.journals.last.notes].uniq)
          .to eq(['The typed note'])
      end

      context 'when making an error in the form' do
        let(:work_package2_status) { create(:status) } # without creating a workflow

        it 'does not update the work packages' do
          fill_in 'work_package_start_date', with: '123'
          click_on 'Submit'

          expect(page)
            .to have_selector(
              '.flash.error',
              text: I18n.t('work_packages.bulk.none_could_be_saved', total: 2)
            )

          expect(page)
            .to have_selector(
              '.flash.error',
              text: "#{work_package.id}: Start date #{I18n.t('activerecord.errors.messages.not_a_date')}"
            )

          expect(page)
            .to have_selector(
              '.flash.error',
              text: <<~MSG.squish
                #{work_package2.id}:
                Status #{I18n.t('activerecord.errors.models.work_package.attributes.status_id.status_transition_invalid')}
              MSG
            )

          # Should not update the status
          work_package2.reload
          work_package.reload
          expect(work_package.status_id).to eq(status.id)
          expect(work_package2.status_id).to eq(work_package2_status.id)
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
# rubocop:enable RSpec/MultipleMemoizedHelpers
