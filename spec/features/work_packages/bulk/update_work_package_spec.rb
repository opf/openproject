require 'spec_helper'
require 'features/page_objects/notification'

describe 'Bulk update work packages through Rails view', js: true do
  shared_let(:type) { create(:type, name: 'Bug') }
  shared_let(:project) { create(:project, name: 'Source', types: [type]) }
  shared_let(:status) { create(:status) }
  shared_let(:custom_field) do
    create(:string_wp_custom_field,
           name: 'Text CF',
           types: [type],
           projects: [project])
  end

  shared_let(:dev_role) do
    create(:role,
           permissions: %i[view_work_packages])
  end
  shared_let(:mover_role) do
    create(:role,
           permissions: %i[view_work_packages copy_work_packages move_work_packages manage_subtasks add_work_packages])
  end
  shared_let(:dev) do
    create(:user,
           firstname: 'Dev',
           lastname: 'Guy',
           member_in_project: project,
           member_through_role: dev_role)
  end
  shared_let(:mover) do
    create(:admin,
           firstname: 'Manager',
           lastname: 'Guy',
           member_in_project: project,
           member_through_role: mover_role)
  end

  shared_let(:work_package) do
    create(:work_package,
           author: dev,
           status:,
           project:,
           type:)
  end

  shared_let(:status2) { create(:default_status) }
  shared_let(:workflow) do
    create(:workflow,
           type_id: type.id,
           old_status: work_package.status,
           new_status: status2,
           role: mover_role)
  end

  let(:work_package2_status) { status }
  let!(:work_package2) do
    create(:work_package,
           author: dev,
           status: work_package2_status,
           project:,
           type:)
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }
  let(:display_representation) { Components::WorkPackages::DisplayRepresentation.new }
  let(:notes) { Components::WysiwygEditor.new }

  before do
    login_as current_user
    wp_table.visit!
    expect_angular_frontend_initialized
    wp_table.expect_work_package_listed work_package, work_package2

    # Select all work packages
    find('body').send_keys [:control, 'a']
  end

  context 'with permission' do
    let(:current_user) { mover }

    before do
      context_menu.open_for work_package
      context_menu.choose 'Bulk edit'

      notes.set_markdown('The typed note')
    end

    it 'sets status and leaves a note' do
      select status2.name, from: 'work_package_status_id'
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
        select status2.name, from: 'work_package_status_id'
        fill_in 'Parent', with: '-1'
        click_on 'Submit'

        expect(page)
          .to have_selector(
            '.flash.error',
            text: I18n.t('work_packages.bulk.none_could_be_saved', total: 2)
          )

        expect(page)
          .to have_selector(
            '.flash.error',
            text: "#{work_package.id}: Parent #{I18n.t('activerecord.errors.messages.does_not_exist')}"
          )

        expect(page)
          .to have_selector(
            '.flash.error',
            text: <<~MSG.squish
              #{work_package2.id}:
              Parent #{I18n.t('activerecord.errors.messages.does_not_exist')}
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

    context 'when editing custom field of work packages with a readonly status (regression#44673)' do
      let(:work_package2_status) { create(:status, :readonly) }

      context 'with enterprise', with_ee: [:readonly_work_packages] do
        it 'does not update the work packages' do
          expect(work_package.send(custom_field.attribute_getter)).to be_nil
          expect(work_package2.send(custom_field.attribute_getter)).to be_nil

          fill_in custom_field.name, with: 'Custom field text'
          click_on 'Submit'

          expect(page)
            .to have_selector(
              '.flash.error',
              text: I18n.t('work_packages.bulk.x_out_of_y_could_be_saved', total: 2, failing: 1, success: 1)
            )

          expect(page)
            .to have_selector(
              '.flash.error',
              text: <<~MSG.squish
                #{work_package2.id}:
                #{custom_field.name} #{I18n.t('activerecord.errors.messages.error_readonly')}
                #{I18n.t('activerecord.errors.models.work_package.readonly_status')}
              MSG
            )

          # Should update 1 work package custom field only
          work_package.reload
          work_package2.reload

          expect(work_package.send(custom_field.attribute_getter))
            .to eq('Custom field text')

          expect(work_package2.send(custom_field.attribute_getter))
            .to be_nil
        end
      end

      context 'without enterprise', with_ee: false do
        it 'ignores the readonly status and updates the work packages' do
          expect(work_package.send(custom_field.attribute_getter)).to be_nil
          expect(work_package2.send(custom_field.attribute_getter)).to be_nil

          fill_in custom_field.name, with: 'Custom field text'
          click_on 'Submit'

          expect(page).to have_selector('.flash.notice', text: I18n.t(:notice_successful_update))

          # Should update 2 work package custom fields
          work_package.reload
          work_package2.reload

          expect(work_package.send(custom_field.attribute_getter))
            .to eq('Custom field text')

          expect(work_package2.send(custom_field.attribute_getter))
            .to eq('Custom field text')
        end
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

      context 'with a project budget' do
        let!(:budget) { create(:budget, project:) }

        it 'updates all the work packages' do
          context_menu.open_for work_package
          context_menu.choose 'Bulk edit'

          select budget.subject, from: 'work_package_budget_id'
          click_on 'Submit'
          expect(work_package.reload.budget_id).to eq(budget.id)
          expect(work_package2.reload.budget_id).to eq(budget.id)
        end
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
