shared_examples 'module specific query view management' do
  describe 'within a module' do
    let(:query_title) { ::Components::WorkPackages::QueryTitle.new }
    let(:query_menu) { ::Components::WorkPackages::QueryMenu.new }
    let(:settings_menu) { Components::WorkPackages::SettingsMenu.new }
    let(:filters) { module_page.filters }

    it 'allows to save, rename and delete a query' do
      # Change the query
      filters.open
      filters.add_filter_by 'Subject', 'contains', ['Test']

      # Save it
      query_title.expect_changed
      settings_menu.open_and_save_query 'My first query'
      query_title.expect_not_changed
      query_title.expect_title 'My first query'
      query_menu.expect_menu_entry 'My first query'

      # Change the filter again
      filters.add_filter_by 'Progress (%)', 'is', ['25'], 'percentageDone'

      # Save as another query
      query_title.expect_changed
      settings_menu.open_and_choose 'Save as ...'
      fill_in 'save-query-name', with: 'My second query'
      click_button 'Save'

      query_title.expect_not_changed
      query_title.expect_title 'My second query'
      query_menu.expect_menu_entry 'My second query'
      query_menu.expect_menu_entry 'My first query'

      # Rename a query
      settings_menu.open_and_choose 'Rename view ...'
      expect(page).to have_focus_on('.editable-toolbar-title--input')
      page.driver.browser.switch_to.active_element.send_keys('My second query (renamed)')
      page.driver.browser.switch_to.active_element.send_keys(:return)
      module_page.expect_and_dismiss_toaster message: I18n.t('js.notice_successful_update')

      query_title.expect_not_changed
      query_title.expect_title 'My second query (renamed)'
      query_menu.expect_menu_entry 'My second query (renamed)'
      query_menu.expect_menu_entry 'My first query'

      # Delete a query
      settings_menu.open_and_choose 'Delete'
      module_page.accept_alert_dialog!
      module_page.expect_and_dismiss_toaster message: I18n.t('js.notice_successful_delete')

      query_title.expect_title default_name
      query_menu.expect_menu_entry_not_visible 'My query planner (renamed)'
      query_menu.expect_menu_entry 'My first query'
    end
  end
end
