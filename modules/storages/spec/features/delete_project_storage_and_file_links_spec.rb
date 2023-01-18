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

# Test if the deletion of a ProjectStorage actually deletes related FileLink
# objects.
describe 'Delete ProjectStorage with FileLinks', js: true do
  let(:user) { create(:user) }
  let(:role) { create(:existing_role, permissions: [:manage_storages_in_project]) }
  let(:project) do
    create(:project,
           name: 'Project 1',
           identifier: 'demo-project',
           members: { user => role },
           enabled_module_names: %i[storages work_package_tracking])
  end
  let(:storage) { create(:storage, name: "Storage 1") }
  let(:work_package) { create(:work_package, project:) }
  let(:project_storage) { create(:project_storage, storage:, project:) }
  let(:file_link) { create(:file_link, storage:, container: work_package) }
  let(:second_file_link) { create(:file_link, container: work_package, storage:) }

  before do
    # The objects defined by let(...) above are lazy instantiated, so we need
    # to "use" (just write their name) below to really create them.
    project_storage
    file_link
    second_file_link
    # Make sure our user has access to the GUI
    login_as user
  end

  it 'deletes ProjectStorage with dependent FileLinks' do
    # Go to Projects -> Settings -> File Storages
    visit project_settings_projects_storages_path(project)

    # The list of enabled file storages should now contain Storage 1
    expect(page).to have_text('File storages available in this project')
    expect(page).to have_text('Storage 1')

    # Press Delete icon to remove the storage from the project
    page.find('.icon.icon-delete').click
    alert_text = page.driver.browser.switch_to.alert.text
    expect(alert_text).to have_text 'Are you sure'
    page.driver.browser.switch_to.alert.accept

    # List of ProjectStorages empty again
    expect(page).to have_current_path project_settings_projects_storages_path(project)
    expect(page).to have_text(I18n.t('storages.no_results'))

    # Also check in the database that ProjectStorage and dependent FileLinks are gone
    expect(Storages::ProjectStorage.count).to be 0
    expect(Storages::FileLink.count).to be 0
  end
end
