require 'spec_helper'
require 'features/page_objects/notification'
require 'support/components/autocompleter/ng_select_autocomplete_helpers'

describe 'Copy work packages through Rails view', js: true do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:type) { create :type, name: 'Bug' }
  shared_let(:type2) { create :type, name: 'Risk' }

  shared_let(:project) { create(:project, name: 'Source', types: [type, type2]) }
  shared_let(:project2) { create(:project, name: 'Target', types: [type, type2]) }

  shared_let(:dev) do
    create :user,
           firstname: 'Dev',
           lastname: 'Guy',
           member_in_project: project,
           member_with_permissions: %i[view_work_packages work_package_assigned]
  end
  shared_let(:mover) do
    create :user,
           firstname: 'Manager',
           lastname: 'Guy',
           member_in_projects: [project, project2],
           member_with_permissions: %i[view_work_packages
                                       copy_work_packages
                                       move_work_packages
                                       manage_subtasks
                                       assign_versions
                                       add_work_packages]
  end

  shared_let(:work_package) do
    create(:work_package,
           author: dev,
           project:,
           type:)
  end
  shared_let(:work_package2) do
    create(:work_package,
           author: dev,
           project:,
           type:)
  end
  shared_let(:version) { create :version, project: project2 }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }
  let(:display_representation) { Components::WorkPackages::DisplayRepresentation.new }
  let(:notes) { Components::WysiwygEditor.new }

  before do
    login_as current_user
    wp_table.visit!
    expect_angular_frontend_initialized
    wp_table.expect_work_package_listed work_package, work_package2
  end

  describe 'copying work packages' do
    before do
      # Select all work packages
      find('body').send_keys [:control, 'a']
    end

    context 'with permission' do
      let(:current_user) { mover }
      let(:wp_table_target) { Pages::WorkPackagesTable.new(project2) }

      before do
        wp_table.expect_work_package_count 2
        context_menu.open_for work_package
        context_menu.choose 'Bulk copy'

        expect(page).to have_selector('#new_project_id')
        expect_page_reload do
          select_autocomplete page.find('[data-qa-selector="new_project_id"]'),
                              query: project2.name,
                              select_text: project2.name,
                              results_selector: 'body'
        end
        sleep(1) # wait for the change of target project to finish updating the page
      end

      it 'sets the version on copy and leaves a note' do
        select version.name, from: 'version_id'
        notes.set_markdown 'A note on copy'
        click_on 'Copy and follow'

        wp_table_target.expect_current_path
        wp_table_target.expect_work_package_count 2
        expect(page).to have_selector('#projects-menu', text: 'Target')

        # Should not move the sources
        work_package2.reload
        work_package.reload

        # Check project of last two created wps
        copied_wps = WorkPackage.last(2)
        expect(copied_wps.map(&:project_id).uniq).to eq([project2.id])
        expect(copied_wps.map(&:version_id).uniq).to eq([version.id])
        expect(copied_wps.map { |wp| wp.journals.last.notes }.uniq).to eq(['A note on copy'])
      end

      context 'with a work package having a child' do
        let!(:child) do
          create(:work_package,
                 author: dev,
                 project:,
                 type:,
                 parent: work_package)
        end

        it 'moves parent and child wp to a new project with the hierarchy amended' do
          click_on 'Copy and follow'

          wp_table_target.expect_current_path
          wp_table_target.expect_work_package_count 3
          expect(page).to have_selector('#projects-menu', text: 'Target')

          # Should not move the sources
          expect(work_package.reload.project_id).to eq(project.id)
          expect(work_package2.reload.project_id).to eq(project.id)

          # Check project of last two created wps
          copied_wps = WorkPackage.last(3)
          expect(copied_wps.map(&:project_id).uniq).to eq([project2.id])

          expect(project2.work_packages.find_by(subject: child.subject).parent)
            .to eq project2.work_packages.find_by(subject: work_package.subject)
        end
      end

      context 'when the target project does not have the type' do
        let!(:child) do
          create(:work_package,
                 author: dev,
                 project:,
                 type:,
                 parent: work_package)
        end

        before do
          project2.types = [type2]
        end

        it 'fails, informing of the reasons' do
          click_on 'Copy and follow'

          expect(page)
            .to have_selector(
              '.flash.error',
              text: I18n.t('work_packages.bulk.none_could_be_saved', total: 3)
            )

          expect(page)
            .to have_selector(
              '.flash.error',
              text: I18n.t('work_packages.bulk.selected_because_descendants', total: 3, selected: 2)
            )

          expect(page)
            .to have_selector(
              '.flash.error',
              text: "#{work_package.id}: Type #{I18n.t('activerecord.errors.messages.inclusion')}"
            )

          expect(page)
            .to have_selector(
              '.flash.error',
              text: "#{work_package2.id}: Type #{I18n.t('activerecord.errors.messages.inclusion')}"
            )

          expect(page)
            .to have_selector(
              '.flash.error',
              text: "#{child.id} (descendant of selected): Type #{I18n.t('activerecord.errors.messages.inclusion')}"
            )
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
      # Select all work packages
      find('body').send_keys [:control, 'a']
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

  describe 'unsetting the assignee as the current assignee is not a member in the project' do
    let(:work_packages) { [work_package] }
    let(:current_user) { mover }
    let(:wp_table) { Pages::WorkPackagesTable.new(project) }

    before do
      work_package.assigned_to = dev
      work_package.save
    end

    it 'copies the work package' do
      context_menu.open_for work_package
      context_menu.choose 'Copy to other project'

      # On work packages move page
      select_autocomplete page.find('[data-qa-selector="new_project_id"]'),
                          query: project2.name,
                          select_text: project2.name,
                          results_selector: 'body'

      # wait for page reload after selecting the target project
      sleep(2)

      select 'nobody', from: 'Assignee'

      click_on 'Copy and follow'

      expect(page)
        .to have_selector('.flash.notice',
                          text: I18n.t(:notice_successful_create))

      wp_page = Pages::FullWorkPackage.new(WorkPackage.last)

      wp_page.expect_attributes assignee: '-'
    end
  end
end
