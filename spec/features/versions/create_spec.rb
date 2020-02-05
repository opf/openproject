#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'version create', type: :feature, js: true do
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i[manage_versions view_work_packages])
    end
  let(:project) { FactoryBot.create(:project) }
  let(:new_version_name) { 'A new version name' }

  before do
    login_as(user)
  end

  context 'create a version' do
    it 'and redirect to default' do
      visit new_project_version_path(project)

      fill_in 'Name', with: new_version_name
      click_on 'Create'

      expect(page).to have_current_path(settings_versions_project_path(project))
      expect(page).to have_content new_version_name
    end


    it 'and redirect back to where you started' do
      visit project_roadmap_path(project)

      click_on 'New version'
      expect(page).to have_current_path(new_project_version_path(project))

      fill_in 'Name', with: new_version_name
      click_on 'Create'

      expect(page).to have_current_path(project_roadmap_path(project))
      expect(page).to have_content new_version_name
    end
  end
end
