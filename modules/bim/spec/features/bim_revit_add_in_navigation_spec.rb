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

require_relative '../spec_helper'

describe 'BIM Revit Add-in navigation spec',
         type: :feature,
         with_config: { edition: 'bim' },
         js: true,
         driver: :chrome_headless_revit_add_in do
  let(:project) { FactoryBot.create :project, enabled_module_names: %i[bim work_package_tracking] }
  let!(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:role) { FactoryBot.create(:role, permissions: %i[view_ifc_models manage_ifc_models view_work_packages]) }
  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }

  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_through_role: role
  end

  context "logged in on model page" do
    let(:model_page) { ::Pages::IfcModels::ShowDefault.new(project) }

    before do
      login_as(user)
      model_page.visit!
    end

    it 'shows "Cards" view by default' do
      model_page.expect_view_toggle_at 'Cards'
    end

    it 'shows no viewer' do
      model_page.model_viewer_visible false
    end

    it 'shows a toolbar' do
      model_page.page_shows_a_toolbar true
    end

    it 'shows no viewer' do
      model_page.model_viewer_visible false
    end

    it 'menu has no viewer options' do
      model_page.has_no_menu_item_with_text? 'Viewer'
    end

    it 'can switch to the Table view mode' do
      model_page.switch_view 'Table'
      expect(page).to have_selector('.work-package-table')
    end

    it 'the user menu has an option to go to the add-in settings' do
      within '.top-menu-items-right' do
        page.find("a[title='#{user.name}']").click

        expect(page).to have_selector('li', text: I18n.t('js.revit.revit_add_in_settings'))
      end
    end

    it 'shows workpackage details page in full view on Cards display mode' do
      card_element = page.find('.wp-card')

      card_element.hover
      card_element.find('.wp-card--details-button').click

      expect(page).to have_selector('.work-packages-partitioned-page--content-right', visible: false)
    end

    it 'shows workpackage details page in full view on Table display mode' do
      model_page.switch_view 'Table'
      row_element = page.first('.wp-table--row')

      row_element.hover
      row_element.find('.wp-table--details-link').click

      expect(page).to have_selector('.work-packages-partitioned-page--content-right', visible: false)
    end
  end

  context "signed out" do
    it 'the user menu has an option to go to the add-in settings' do
      visit home_path

      click_link I18n.t(:label_login)

      expect(page).to have_text(I18n.t('js.revit.revit_add_in_settings'))
    end
  end
end
