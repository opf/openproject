# frozen_string_literal: true

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

module Pages
  module Projects
    module Settings
      class LifeCycle < Pages::Page
        attr_reader :project

        def initialize(project)
          super()

          @project = project
        end

        def path
          "/projects/#{project.identifier}/settings/life_cycle"
        end

        # Checks if the life cycle steps are listed in the order given and with the correct toggle state.
        # @param life_cycle_definitions [Hash{LifeCycleElement => Boolean}]
        def expect_listed(**life_cycle_steps)
          life_cycle_steps.each_cons(2) do |(predecessor, _), (successor, _)|
            expect(page).to have_css("#{life_cycle_test_selector(predecessor)} ~ #{life_cycle_test_selector(successor)}")
          end

          life_cycle_steps.each do |step, active|
            expect_toggle_state(step, active)
          end
        end

        def expect_not_listed(*life_cycle_steps)
          life_cycle_steps.each do |step|
            expect(page).to have_no_css(life_cycle_test_selector(step))
          end
        end

        def expect_toggle_state(definition, active)
          within toggle_step(definition) do
            expect(page)
              .to have_css(".ToggleSwitch-status#{expected_toggle_status(active)}"),
                  "Expected toggle for '#{definition.name}' to be #{expected_toggle_status(active)} " \
                  "but was #{expected_toggle_status(!active)}"
          end
        end

        def toggle(definition)
          toggle_step(definition).click
        end

        def disable_all
          find_test_selector("disable-all-life-cycle-steps").click
        end

        def enable_all
          find_test_selector("enable-all-life-cycle-steps").click
        end

        def life_cycle_test_selector(definition)
          test_selector("project-life-cycle-step-#{definition.id}")
        end

        def toggle_step(definition)
          find_test_selector("toggle-project-life-cycle-#{definition.id}")
        end

        def filter_by(filter)
          fill_in I18n.t("projects.settings.life_cycle.filter.label"), with: filter
        end

        def expected_toggle_status(active)
          active ? "On" : "Off"
        end

        # Reloads the page and via the check carried out on the Home page
        # a proper reload is ensured.
        def reload_with_home_page_detour
          visit home_path

          expect(page)
            .to have_css(".PageHeader-title", text: "OpenProject")

          visit!
        end
      end
    end
  end
end
