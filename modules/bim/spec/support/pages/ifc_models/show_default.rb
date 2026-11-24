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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
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
        expect(page).to have_css(".xeokit-toolbar", wait: 30)
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
        expect(page).to have_conditional_selector(visible, :button, accessible_name: I18n.t("js.bcf.refresh_work_package"))
      end

      def click_refresh_button
        click_on accessible_name: I18n.t("js.bcf.refresh_work_package")
      end

      def switch_view(value)
        view_toggle.click
        within(:menu, I18n.t("js.bcf.view_select")) do
          find(:role, "menuitemradio", exact_text: value).click
        end
      end

      def expect_view_toggle_at(value)
        expect(page).to have_button(accessible_name: value, exact: true)
      end

      def expect_view_options(*values, checked:)
        view_toggle.click
        within(:menu, I18n.t("js.bcf.view_select")) do
          expect(page).to have_selector(:role, "menuitemradio", count: values.size)
          values.each { |value| expect(page).to have_selector(:role, "menuitemradio", exact_text: value) }
          expect(page).to have_selector(:role, "menuitemradio", exact_text: checked, aria: { checked: true })
        end
        page.send_keys(:escape)
      end

      private

      def view_toggle
        find(:button, accessible_name: /\A#{Regexp.union(view_names)}\z/)
      end

      def view_names
        [
          I18n.t("js.ifc_models.views.viewer"),
          I18n.t("js.views.card"),
          I18n.t("js.ifc_models.views.split_cards"),
          I18n.t("js.ifc_models.views.split"),
          I18n.t("js.views.list")
        ]
      end

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
