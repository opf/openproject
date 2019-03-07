require 'spec_helper'

describe 'Watcher tab', js: true, selenium: true do
  include ::Components::NgSelectAutocompleteHelpers

  let(:project) { FactoryBot.create(:project) }
  let(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:tabs) { ::Components::WorkPackages::Tabs.new(work_package) }

  let(:user) { FactoryBot.create(:user, member_in_project: project, member_through_role: role) }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) {
    %i(view_work_packages
       view_work_package_watchers
       delete_work_package_watchers
       add_work_package_watchers)
  }

  let(:watch_button) { find '#watch-button' }
  let(:watchers_tab) { find('.tabrow li.selected', text: 'WATCHERS') }

  def expect_button_is_watching
    title = I18n.t('js.label_unwatch_work_package')
    expect(page).to have_selector("#unwatch-button[title='#{title}']")
    expect(page).to have_selector('#unwatch-button .button--icon.icon-watched')
  end

  def expect_button_is_not_watching
    title = I18n.t('js.label_watch_work_package')
    expect(page).to have_selector("#watch-button[title='#{title}']")
    expect(page).to have_selector('#watch-button .button--icon.icon-unwatched')
  end

  shared_examples 'watch and unwatch with button' do
    it 'watching the WP modifies the watcher list' do
      # Expect WP watch button is in not-watched state
      expect_button_is_not_watching
      expect(page).to have_no_selector('.work-package--watcher-name')
      watch_button.click

      # Expect WP watch button causes watcher list to add user
      expect_button_is_watching
      expect(page).to have_selector('.work-package--watcher-name', count: 1, text: user.name)

      # Expect WP unwatch button causes watcher list to remove user
      watch_button.click
      expect_button_is_not_watching
      expect(page).to have_no_selector('.work-package--watcher-name')
    end
  end

  shared_examples 'watchers tab' do
    before do
      login_as(user)
      wp_page.visit_tab! :watchers
      expect_angular_frontend_initialized
      expect(page).to have_selector('.tabrow li.selected', text: 'WATCHERS')
    end

    it 'modifying the watcher list modifies the watch button' do
      # Add user as watcher
      autocomplete = find('.wp-watcher--autocomplete')
      select_autocomplete autocomplete,
                          query: user.firstname,
                          select_text: user.name

      # Expect the addition of the user to toggle WP watch button
      expect(page).to have_selector('.work-package--watcher-name', count: 1, text: user.name)
      expect_button_is_watching

      # Expect watchers counter to increase
      tabs.expect_counter(watchers_tab, 1)

      # Remove watcher from list
      page.find('wp-watcher-entry', text: user.name).hover
      page.find('.form--selected-value--remover').click

      # Watchers counter should not be displayed
      tabs.expect_no_counter(watchers_tab)

      # Expect the removal of the user to toggle WP watch button
      expect(page).to have_no_selector('.work-package--watcher-name')
      expect_button_is_not_watching
    end

    context 'with a user with arbitrary characters' do
      let!(:html_user) {
        FactoryBot.create :user,
                           firstname: '<em>foo</em>',
                           member_in_project: project,
                           member_through_role: role
      }

      it 'escapes the user name' do
        autocomplete = find('.wp-watcher--autocomplete')
        target_dropdown = search_autocomplete autocomplete,
                                              query: 'foo'

        expect(target_dropdown).to have_selector(".ng-option", text: html_user.firstname)
        expect(target_dropdown).to have_no_selector(".ng-option em")
      end
    end

    context 'with all permissions' do
      it_behaves_like 'watch and unwatch with button'
    end

    context 'without watchers permission' do
      let(:permissions) { %i(view_work_packages view_work_package_watchers) }
      it_behaves_like 'watch and unwatch with button'
    end
  end

  context 'split screen' do
    let(:wp_page) { Pages::SplitWorkPackage.new(work_package) }
    it_behaves_like 'watchers tab'
  end

  context 'full screen' do
    let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
    it_behaves_like 'watchers tab'
  end
end
