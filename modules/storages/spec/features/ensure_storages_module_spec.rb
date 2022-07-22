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

describe 'Ensure storages module', type: :feature, js: true do
  current_user { create(:admin) }

  let(:role) do
    create(:role,
           permissions: %i[manage_storages_in_project
                           select_project_modules
                           edit_project])
  end
  let(:storage) { create(:storage, name: "Storage 1") }
  let(:project) do
    create(:project,
           enabled_module_names: %i[storages work_package_tracking])
  end

  before do
    storage
    project
  end

  around do |example|
    old_value = Capybara.raise_server_errors
    Capybara.raise_server_errors = false
    example.run
  ensure
    Capybara.raise_server_errors = old_value
  end

  it 'shows storages on administration and project pages' do
    expect_pages_to_include_storages_information
  end

  def expect_pages_to_include_storages_information
    run_administration_pages_assertions_about_storages_visibility
    run_project_pages_assertions_about_storages_visibility
    run_permissions_pages_assertions_about_storages_visibility
  end

  def run_administration_pages_assertions_about_storages_visibility
    visit admin_index_path
    within '#menu-sidebar' do
      expect(page).to have_text(I18n.t(:project_module_storages))
    end
    within '#content' do
      expect(page).to have_text(I18n.t(:project_module_storages))
    end

    visit admin_settings_projects_path
    within '#content' do
      expect(page).to have_text(I18n.t(:project_module_storages))
    end

    visit admin_settings_storages_path
    expect(page).to have_text(I18n.t(:project_module_storages))
  end

  def run_project_pages_assertions_about_storages_visibility
    visit project_settings_modules_path(project)
    within '#menu-sidebar' do
      expect(page).to have_text(I18n.t(:project_module_storages))
    end
    within '#content' do
      expect(page).to have_text(I18n.t(:project_module_storages))
    end

    visit project_settings_projects_storages_path(project)
    expect(page).to have_text(I18n.t('storages.page_titles.project_settings.index'))
  end

  def run_permissions_pages_assertions_about_storages_visibility
    visit new_role_path
    within '#content' do
      expect(page).to have_text(I18n.t(:project_module_storages).upcase)
    end

    visit edit_role_path(role)
    within '#content' do
      expect(page).to have_text(I18n.t(:project_module_storages).upcase)
    end

    visit report_roles_path(role)
    within '#content' do
      expect(page).to have_text(I18n.t(:project_module_storages).upcase)
    end
  end
end
