require 'spec_helper'

require 'features/work_packages/work_packages_page'
require 'support/work_packages/work_package_field'

describe 'Watcher tab', js: true, selenium: true do
  let(:project) { FactoryGirl.create(:project) }
  let(:work_package) { FactoryGirl.create(:work_package, project: project) }

  let(:user) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:permissions) {
    %i(view_work_packages
       view_work_package_watchers
       delete_work_package_watchers
       add_work_package_watchers)
  }

  let(:watch_button) { find '#watch-button' }

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
    include_context 'ui-autocomplete helpers'

    before do
      login_as(user)
      wp_page.visit_tab! :watchers
      expect(page).to have_selector('.tabrow li.selected', text: 'WATCHERS')
    end

    it 'modifying the watcher list modifies the watch button' do
      # Add user as watcher
      autocomplete = find('.wp-watcher--autocomplete')
      select_autocomplete(autocomplete, query: user.firstname, select_text: user.name)

      # Expect the addition of the user to toggle WP watch button
      expect(page).to have_selector('.work-package--watcher-name', count: 1, text: user.name)
      expect_button_is_watching

      # Remove watcher from list
      page.find('.watcher-element', text: user.name).hover
      page.find('.remove-watcher-btn').click

      # Expect the removal of the user to toggle WP watch button
      expect(page).to have_no_selector('.work-package--watcher-name')
      expect_button_is_not_watching
    end

    context 'with a user with arbitrary characters' do
      let!(:html_user) {
        FactoryGirl.create :user,
                           firstname: '<em>foo</em>',
                           member_in_project: project,
                           member_through_role: role
      }

      it 'escapes the user name' do
        autocomplete = find('.wp-watcher--autocomplete')
        target_dropdown = search_autocomplete(autocomplete, query: 'foo')

        expect(target_dropdown).to have_selector(".ui-menu-item", text: html_user.firstname)
        expect(target_dropdown).to have_no_selector(".ui-menu-item em")
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
