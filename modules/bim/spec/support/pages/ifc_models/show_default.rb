#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "support/pages/page"
require_relative "../bcf/create_split"

module Pages
  module IfcModels
    class ShowDefault < ::Pages::WorkPackageCards
      include ::Pages::WorkPackages::Concerns::WorkPackageByButtonCreator

      attr_accessor :project,
                    :filters

      def initialize(project)
        super()

        self.project = project
        self.filters = ::Components::WorkPackages::Filters.new
      end

      def path
        defaults_bcf_project_ifc_models_path(project)
      end

      def visit_and_wait_until_finished_loading!
        visit!
        finished_loading
      end

      # Visits the BCF module with the specified query.
      #
      # @param query [Query] The query object.
      def visit_query(query)
        visit "#{path}?query_id=#{query.id}"
      end

      def expect_details_path
        expect(page).to have_current_path /\/bcf\/details/, ignore_query: true
      end

      def finished_loading
        expect(page).to have_css(".xeokit-busy-modal", visible: :all, wait: 30)
      end

      def model_viewer_visible(visible)
        # Ensure the canvas is present
        canvas_selector = ".op-ifc-viewer--model-canvas"
        expect(page).to(visible ? have_selector(canvas_selector, wait: 10) : have_no_selector(canvas_selector, wait: 10))
        # Ensure Xeokit is initialized. Only then the toolbar is generated.
        toolbar_selector = ".xeokit-toolbar"
        expect(page).to(visible ? have_selector(toolbar_selector, wait: 10) : have_no_selector(toolbar_selector, wait: 10))
      end

      def model_viewer_shows_a_toolbar(visible)
        selector = ".xeokit-btn"

        if visible
          within('[data-test-selector="op-ifc-viewer--toolbar-container"]') do
            expect(page).to have_selector(selector, count: 10)
          end
        else
          expect(page).to have_no_selector(selector)
          expect(page).to have_no_css('[data-test-selector="op-ifc-viewer--toolbar-container"]')
        end
      end

      def page_shows_a_toolbar(visible)
        toolbar_items.each do |button|
          expect(page).to have_conditional_selector(visible, ".toolbar-item", text: button)
        end
      end

      def page_has_a_toolbar
        expect(page).to have_css(".toolbar-container")
      end

      def page_shows_a_filter_button(visible)
        expect(page).to have_conditional_selector(visible, ".toolbar-item", text: "Filter")
      end

      def page_shows_a_refresh_button(visible)
        expect(page).to have_conditional_selector(visible, ".toolbar-item a.refresh-button")
      end

      def click_refresh_button
        page.find(".toolbar-item a.refresh-button").click
      end

      def switch_view(value)
        retry_block do
          page.find_by_id("bcf-view-toggle-button").click
          within("#bcf-view-context-menu") do
            page.find(".menu-item", text: value, exact_text: true).click
          end
        end
      end

      def expect_view_toggle_at(value)
        expect(page).to have_css("#bcf-view-toggle-button", text: value)
      end

      def has_no_menu_item_with_text?(value)
        expect(page).to have_no_css(".menu-item", text: value)
      end

      private

      def toolbar_items
        ["IFC models"]
      end

      def create_page_class_instance(type)
        create_page_class.new(project:, type_id: type.id)
      end

      def create_page_class
        Pages::BCF::CreateSplit
      end
    end
  end
end
