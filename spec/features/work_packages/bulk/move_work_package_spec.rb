require 'spec_helper'
require 'features/page_objects/notification'
require 'support/components/autocompleter/ng_select_autocomplete_helpers'

describe 'Moving a work package through Rails view', js: true do
  include ::Components::Autocompleter::NgSelectAutocompleteHelpers

  let(:dev_role) do
    create(:role,
           permissions: %i[view_work_packages add_work_packages])
  end
  let(:mover_role) do
    create(:role,
           permissions: %i[view_work_packages move_work_packages manage_subtasks add_work_packages])
  end
  let(:dev) do
    create(:user,
           firstname: 'Dev',
           lastname: 'Guy',
           member_in_project: project,
           member_through_role: dev_role)
  end
  let(:mover) do
    create(:admin,
           firstname: 'Manager',
           lastname: 'Guy',
           member_in_project: project,
           member_through_role: mover_role)
  end

  let(:type) { create(:type, name: 'Bug') }
  let(:type2) { create(:type, name: 'Risk') }

  let!(:project) { create(:project, name: 'Source', types: [type, type2]) }
  let!(:project2) { create(:project, name: 'Target', types: [type, type2]) }

  let(:work_package) do
    create(:work_package,
           author: dev,
           project:,
           type:,
           status:)
  end
  let(:work_package2) do
    create(:work_package,
           author: dev,
           project:,
           type:,
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
             project:,
             type:,
             status:)
    end

    context 'with permission' do
      before do
        expect(child_wp.project_id).to eq(project.id)

        context_menu.open_for work_package
        context_menu.choose 'Change project'

        # On work packages move page
        expect(page).to have_selector('#new_project_id')
        select_autocomplete page.find('[data-qa-selector="new_project_id"]'),
                            query: 'Target',
                            select_text: 'Target',
                            results_selector: 'body'
        SeleniumHubWaiter.wait
      end

      it 'moves parent and child wp to a new project' do
        # Clicking move and follow might be broken due to the location.href
        # in the refresh-on-form-changes component
        retry_block do
          click_on 'Move and follow'
          page.find('.inline-edit--container.subject', text: work_package.subject, wait: 10)
          page.find_by_id('projects-menu', text: 'Target')
        end

        # Should move its children
        child_wp.reload
        expect(child_wp.project_id).to eq(project2.id)
      end

      context 'when the target project does not have the type' do
        let!(:project2) { create(:project, name: 'Target', types: [type2]) }

        it 'does moves the work package and changes the type' do
          # Clicking move and follow might be broken due to the location.href
          # in the refresh-on-form-changes component
          retry_block do
            click_on 'Move and follow'
            page.find('.inline-edit--container.subject', text: work_package.subject, wait: 10)
            page.find_by_id('projects-menu', text: 'Target')
          end

          # Should NOT have moved
          child_wp.reload
          work_package.reload
          expect(work_package.project_id).to eq(project2.id)
          expect(work_package.type_id).to eq(type2.id)
          expect(child_wp.project_id).to eq(project2.id)
          expect(child_wp.type_id).to eq(type2.id)
        end
      end

      context 'when the target project has a type with a required field' do
        let(:required_cf) { create(:int_wp_custom_field, is_required: true) }
        let(:type2) { create(:type, name: 'Risk', custom_fields: [required_cf]) }
        let!(:project2) { create(:project, name: 'Target', types: [type2], work_package_custom_fields: [required_cf]) }

        it 'does not moves the work package when the required field is missing' do
          select "Risk", from: "Type"
          expect(page).to have_field(required_cf.name)

          # Clicking move and follow might be broken due to the location.href
          # in the refresh-on-form-changes component
          retry_block do
            click_on 'Move and follow'
          end

          expect(page)
            .to have_selector('.flash.error',
                              text: I18n.t(:'work_packages.bulk.none_could_be_saved',
                                           total: 1))
          child_wp.reload
          work_package.reload
          expect(work_package.project_id).to eq(project.id)
          expect(work_package.type_id).to eq(type.id)
          expect(child_wp.project_id).to eq(project.id)
          expect(child_wp.type_id).to eq(type.id)
        end

        it 'does moves the work package when the required field is set' do
          select "Risk", from: "Type"
          fill_in required_cf.name, with: '1'

          # Clicking move and follow might be broken due to the location.href
          # in the refresh-on-form-changes component
          retry_block do
            click_on 'Move and follow'
          end

          expect(page).to have_selector('.flash.notice')

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
      select_autocomplete page.find('[data-qa-selector="new_project_id"]'),
                          query: project2.name,
                          select_text: project2.name,
                          results_selector: 'body'
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
