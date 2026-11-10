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
      class Modules < Pages::Page
        attr_accessor :project

        def initialize(project)
          super()

          self.project = project
        end

        def path
          "/projects/#{project.identifier}/settings/modules"
        end

        # The toggle flips optimistically before the request completes, so waiting on its
        # state alone would race the server.
        def toggle_module(name)
          within_test_selector(toggle_selector(name)) { click_button }
          wait_for_network_idle
        end

        def expect_module_enabled(name, enabled: true)
          expect(page).to have_css("#{toggle_css(name)} button[aria-pressed='#{enabled}']")
        end

        def expect_module_locked(name)
          expect(page).to have_css("#{toggle_css(name)} button[disabled]")
        end

        def expect_module_unlocked(name)
          expect(page).to have_css("#{toggle_css(name)} button:not([disabled])")
        end

        def expect_lock_reason(name)
          expect(page).to have_css("#project-module-#{name}-disabled-reason", visible: :all)
        end

        private

        def toggle_selector(name) = "toggle-project-module-#{name}"

        def toggle_css(name) = "[data-test-selector='#{toggle_selector(name)}']"
      end
    end
  end
end
