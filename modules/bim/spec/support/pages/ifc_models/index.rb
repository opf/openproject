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

require 'support/pages/page'
require 'support/pages/work_packages/concerns/work_package_by_button_creator'

module Pages
  module IfcModels
    class Index < ::Pages::Page
      attr_accessor :project

      def initialize(project)
        self.project = project
      end

      def path
        bcf_project_ifc_models_path(project)
      end

      def model_listed(listed, model_name)
        within '.generic-table' do
          expect(page).to (listed ? have_text(model_name) : have_no_text(model_name))
        end
      end

      def add_model_allowed(allowed)
        if allowed
          click_toolbar_button 'IFC model'

          expect_correct_page_loaded '.button[type="submit"]'
          expect(page).to have_current_path new_bcf_project_ifc_model_path(project)

          visit!
        else
          expect(page).to have_no_selector('.button.-alt-highlight', text: 'IFC model')
        end
      end

      def bcf_buttons(allowed)
        expect(page).to have_conditional_selector(allowed, '.toolbar-item', text: 'Import')
        expect(page).to have_conditional_selector(allowed, '.toolbar-item', text: 'Export')
      end

      def edit_model_allowed(model_name, allowed)
        row = find_model_table_row model_name
        within row do
          expect(page).to (allowed ? have_selector('.icon-edit') : have_no_selector('.icon-edit'))
        end
      end

      def delete_model_allowed(model_name, allowed)
        row = find_model_table_row model_name
        within row do
          expect(page).to (allowed ? have_selector('.icon-edit') : have_no_selector('.icon-edit'))
        end
      end

      def edit_model(model_name, new_name)
        click_table_icon model_name, '.icon-edit'

        change_model_name model_name, new_name
        click_on 'Save'

        model_listed true, new_name
        expect(current_path).to eq bcf_project_ifc_models_path(project)
      end

      def delete_model(model_name)
        click_table_icon model_name, '.icon-delete'

        page.driver.browser.switch_to.alert.accept

        model_listed false, model_name
        expect(current_path).to eq bcf_project_ifc_models_path(project)
      end

      def show_model(model)
        click_model_link model.title

        expect_correct_page_loaded '.ifc-model-viewer--container'

        expect(page).to have_selector('.editable-toolbar-title--fixed', text: model.title)
      end

      def show_defaults
        click_toolbar_button 'Show defaults'

        expect_correct_page_loaded '.ifc-model-viewer--container'

        expect(page).to have_selector('.editable-toolbar-title--fixed', text: 'Default IFC models')
      end

      private

      def find_model_table_row(model_name)
        within '.generic-table' do
          page.find('td', text: model_name).find(:xpath, '..')
        end
      end

      def click_model_link(model_name)
        within '.generic-table' do
          page.find('td a', text: model_name).click
        end
      end

      def click_toolbar_button(name)
        within '.toolbar' do
          page.find('.button', text: name).click
        end
      end

      def click_table_icon(model_name, icon_class)
        row = find_model_table_row model_name
        within row do
          page.find(icon_class).click
        end
      end

      def expect_correct_page_loaded(checked_selector)
        expect(page).to have_selector(checked_selector)
      end

      def change_model_name(model_name, new_name)
        expect(page).to have_selector('input[type="file"]')
        expect(page).to have_field('bim_ifc_models_ifc_model[title]', with: model_name)
        fill_in 'bim_ifc_models_ifc_model[title]', with: new_name
      end
    end
  end
end
