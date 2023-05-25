#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative '../spec_helper'

# Setup storages in Project -> Settings -> File Storages
# This tests assumes that a Storage has already been setup
# in the Admin section, tested by admin_storage_spec.rb.
describe 'Activation of storages in projects', js: true, with_flag: { storage_project_folders: true } do
  let(:user) { create(:user) }
  # The first page is the Project -> Settings -> General page, so we need
  # to provide the user with the edit_project permission in the role.
  let(:role) do
    create(:role,
           permissions: %i[manage_storages_in_project
                           select_project_modules
                           edit_project])
  end
  let(:storage) { create(:storage, name: "Storage 1") }
  let(:project) do
    create(:project,
           members: { user => role },
           enabled_module_names: %i[storages work_package_tracking])
  end
  let(:location_picker) { Components::FilePickerDialog.new }

  before do
    storage
    project
    login_as user
  end

  fit 'adds, edits and removes storages to projects' do
    # Go to Projects -> Settings -> File Storages
    visit project_settings_general_path(project)
    page.find('.settings-projects-storages-menu-item').click

    # Check for an empty table in Project -> Settings -> File storages
    expect(page).to have_title('File storages')
    expect(page).to have_current_path project_settings_projects_storages_path(project)
    expect(page).to have_text(I18n.t('storages.no_results'))
    page.find('.toolbar .button--icon.icon-add').click

    # Can cancel the creation of a new file storage and view help text
    expect(page).to have_current_path new_project_settings_projects_storage_path(project_id: project)
    expect(page).to have_text('Add a file storage')
    page.find('[data-qa-selector="static-attribute-help-text--icon"]').click
    expect(page).to have_selector('[data-qa-selector="static-attribute-help-text--modal"]')
    page.click_button('Close')
    page.click_link('Cancel')
    expect(page).to have_current_path project_settings_projects_storages_path(project)

    # Enable one file storage together with a project folder mode
    page.find('.toolbar .button--icon.icon-add').click
    expect(page).to have_current_path new_project_settings_projects_storage_path(project_id: project)
    expect(page).to have_text('Add a file storage')
    expect(page).to have_select('storages_project_storage_storage_id', options: ['Storage 1 (nextcloud)'])
    page.find_by_id('storages_project_storage_project_folder_mode_manual').click

    # Select project folder
    expect(page).to have_text('No selected folder')
    page.click_button('Select Folder')
    location_picker.expect_open


    page.click_button('Add')

    # The list of enabled file storages should now contain Storage 1
    expect(page).to have_text('File storages available in this project')
    expect(page).to have_text('Storage 1')

    # Press Edit icon to change the project folder mode to inactive
    page.find('.icon.icon-edit').click
    expect(page).to have_current_path edit_project_settings_projects_storage_path(project_id: project,
                                                                                  id: Storages::ProjectStorage.last)
    expect(page).to have_text('Edit the file storage to this project')
    expect(page).not_to have_select('storages_project_storage_storage_id')
    expect(page).to have_text('Storage 1')
    expect(page).to have_checked_field('storages_project_storage_project_folder_mode_manual')
    expect(page).to have_field('storages_project_storage_project_folder_id', with: 'Project#1')

    # Change the project folder mode to inactive, project folder is hidden but retained
    page.find_by_id('storages_project_storage_project_folder_mode_inactive').click
    expect(page).not_to have_field('storages_project_storage_project_folder_id', with: 'Project#1')
    expect(page).to have_css('#storages_project_storage_project_folder_id', visible: :hidden)
    page.click_button('Save')

    # The list of enabled file storages should still contain Storage 1
    expect(page).to have_text('File storages available in this project')
    expect(page).to have_text('Storage 1')

    # Click Edit icon again but cancel the edit
    page.find('.icon.icon-edit').click
    expect(page).to have_current_path edit_project_settings_projects_storage_path(project_id: project,
                                                                                  id: Storages::ProjectStorage.last)
    expect(page).to have_text('Edit the file storage to this project')
    page.click_link('Cancel')
    expect(page).to have_current_path project_settings_projects_storages_path(project)

    # Press Delete icon to remove the storage from the project
    page.find('.icon.icon-delete').click
    alert_text = page.driver.browser.switch_to.alert.text
    expect(alert_text).to have_text 'Are you sure'
    page.driver.browser.switch_to.alert.accept

    # List of ProjectStorages empty again
    expect(page).to have_current_path project_settings_projects_storages_path(project)
    expect(page).to have_text(I18n.t('storages.no_results'))
  end
end
