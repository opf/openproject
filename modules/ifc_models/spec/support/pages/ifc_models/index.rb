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

module Pages
  module IfcModels
    class Index < ::Pages::Page
      attr_accessor :project

      def initialize(project)
        self.project = project
      end

      def path
        ifc_models_project_ifc_models_path(project)
      end

      def model_listed(listed, model_name)
        within '.generic-table' do
          expect(page).to (listed ? have_text(model_name) : have_no_text(model_name))
        end
      end

      def add_model_allowed(allowed)
        if allowed
          within '.toolbar' do
            page.find('.button.-alt-highlight', text: 'IFC model').click
          end

          expect(page).to have_text('New IFC model')
          expect(current_path).to eql new_ifc_models_project_ifc_model_path(project)

          visit!
        else
          expect(page).to have_no_selector('.button.-alt-highlight', text: 'IFC model')
        end
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
        row = find_model_table_row model_name
        within row do
          page.find('.icon-edit').click
        end

        expect(page).to have_selector('input[type="file"]')
        expect(page).to have_field('ifc_models_ifc_model[title]', with: model_name)
        fill_in 'ifc_models_ifc_model[title]', with: new_name

        click_on 'Save'

        model_listed true, new_name
        expect(current_path).to eq ifc_models_project_ifc_models_path(project)
      end

      def delete_model(model_name)
        row = find_model_table_row model_name
        within row do
          page.find('.icon-delete').click
        end

        page.driver.browser.switch_to.alert.accept

        model_listed false, model_name
        expect(current_path).to eq ifc_models_project_ifc_models_path(project)
      end

      def show_model(model)
        within '.generic-table' do
          page.find('td a', text: model.title).click
        end

        expect(page).to have_selector('.ifc-model-viewer--container')
        expect(current_path).to eq ifc_models_project_ifc_model_path(project, model)

        visit!
      end

      def show_defaults
        within '.toolbar' do
          page.find('.button', text: 'Show defaults').click
        end

        expect(page).to have_selector('.ifc-model-viewer--container')
        expect(current_path).to eq show_defaults_ifc_models_project_ifc_models_path(project)

        visit!
      end

      private

      def find_model_table_row(model_name)
        within '.generic-table' do
          page.find('td', text: model_name).find(:xpath, '..')
        end
      end
    end
  end
end
