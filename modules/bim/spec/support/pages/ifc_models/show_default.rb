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
require_relative '../bcf/create_split'

module Pages
  module IfcModels
    class ShowDefault < ::Pages::WorkPackageCards
      include ::Pages::WorkPackages::Concerns::WorkPackageByButtonCreator

      attr_accessor :project

      def initialize(project)
        self.project = project
      end

      def path
        defaults_bcf_project_ifc_models_path(project)
      end

      def finished_loading
        expect(page).to have_no_selector('.xeokit-busy-modal', visible: true)
      end

      def model_viewer_visible(visible)
        selector = '.ifc-model-viewer--model-canvas'
        expect(page).to (visible ? have_selector(selector) : have_no_selector(selector))
      end

      def model_viewer_shows_a_toolbar(visible)
        selector = '.xeokit-btn'

        if visible
          within ('.ifc-model-viewer--toolbar-container') do
            expect(page).to have_selector(selector, count: 8)
          end
        else
          expect(page).to have_no_selector(selector)
          expect(page).to have_no_selector('.ifc-model-viewer--toolbar-container')
        end
      end

      def page_shows_a_toolbar(visible)
        toolbar_items.each do |button|
          expect(page).to have_conditional_selector(visible, '.toolbar-item', text: button)
        end
      end

      def page_shows_a_filter_button(visible)
        expect(page).to have_conditional_selector(visible, '.toolbar-item', text: 'Filter')
      end

      def switch_view(value)
        page.find('#bim-view-toggle-button').click
        page.find('.menu-item', text: value).click
      end

      def expect_view_toggle_at(value)
        expect(page).to have_selector('#bim-view-toggle-button', text: value)
      end

      private

      def toolbar_items
        ['Manage models']
      end

      def create_page_class_instance(type)
        create_page_class.new(project: project, type_id: type.id)
      end

      def create_page_class
        Pages::BCF::CreateSplit
      end
    end
  end
end
