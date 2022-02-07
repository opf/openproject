#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

# Setup a project storage within a project.
# This tests assumes that a Storage has already been setup
# in the Admin section, tested by admin_storage_spec.rb.


describe 'Setup project storage', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:storage) { create(:storage, name: "Storage 1") }
  let(:project) { create(:project, name: 'Project 1', identifier: 'demo-project', enabled_module_names: [:storages, :work_package_tracking]) }
  let(:work_package) { create(:work_package, project: project) }
  let(:project_storage) { create(:project_storage, { storage: storage, project: project }) }

  before do
    storage
    # project_storage # Now created via testing GUI
    login_as admin
  end

  it 'setup project storage' do
    # Go to Projects -> Settings -> File Storages
    # project_settings_work_packages doesn't seem to exist, so I work around
    visit project_settings_general_path(project)
    settings_link = page.find('.settings-projects-storages-menu-item')
    settings_link.click

    # Check for an empty Project -> Settings -> File storages page
    expect(page).to have_title('File storages')
    expect(page).to have_text('No storage setup, yet.')
    page.find('.toolbar .button--icon.icon-add').click

    # Enable the one and oly file storage
    expect(page).to have_title('File storages')
    expect(page).to have_text('Enable a file storage')
    page.find('button[type=submit]').click

    # The list of enabled file storages should now contain Storage 1
    expect(page).to have_title('File storages')
    expect(page).to have_text('File storages available in this project')
    expect(page).to have_text('Storage 1')

    # Go to the Work Package in order to add a file link
    visit work_package_path(work_package)
    # Here we'd expect functionality wrt adding a file_link,
    # which doesn't seem to exist yet.
    # binding.pry

  end
end
