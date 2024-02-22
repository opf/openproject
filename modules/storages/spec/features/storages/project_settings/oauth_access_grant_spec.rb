# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require 'spec_helper'
require_module_spec_helper

RSpec.describe 'OAuth Access Grant Nudge upon adding a storage to a project',
               :js,
               :webmock do
  shared_let(:user) { create(:user, preferences: { time_zone: 'Etc/UTC' }) }

  shared_let(:role) do
    create(:project_role, permissions: %i[manage_storages_in_project
                                          oauth_access_grant
                                          select_project_modules
                                          edit_project])
  end

  shared_let(:storage) { create(:nextcloud_storage_with_complete_configuration) }

  shared_let(:project) do
    create(:project,
           name: "Project name without sequence",
           members: { user => role },
           enabled_module_names: %i[storages work_package_tracking])
  end

  current_user { user }

  it 'adds a storage, nudges the project admin to grant OAuth access' do
    visit project_settings_project_storages_path(project_id: project)

    click_on('Storage')

    expect(page).to have_select('Storage', options: ["#{storage.name} (nextcloud)"])
    click_on('Continue')

    # by default automatic have to be choosen if storage has automatic management enabled
    expect(page).to have_checked_field("New folder with automatically managed permissions")
    click_on('Add')

    # The list of enabled file storages should now contain Storage 1
    expect(page).to have_text('File storages available in this project')
    expect(page).to have_text(storage.name)

    within_test_selector('oauth-access-grant-nudge-modal') do
      expect(page).to be_axe_clean
      expect(page).to have_text('One more step...')
      click_on('Login')

      expect(page).to have_text("Requesting access to #{storage.name}")
      expect(page).to be_axe_clean
    end
  end
end
