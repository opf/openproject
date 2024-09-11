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

module Components
  module Timelines
    class ConfigurationModal
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers

      attr_reader :settings_menu

      def initialize
        @modal = ::Components::WorkPackages::TableConfigurationModal.new
      end

      def open!
        @modal.open_and_switch_to "Gantt chart"
      end

      def get_select(position)
        page.find("#modal-timelines-label-#{position}")
      end

      def expect_labels!(left:, right:, farRight:)
        expect(page).to have_select("modal-timelines-label-left", selected: left)
        expect(page).to have_select("modal-timelines-label-right", selected: right)
        expect(page).to have_select("modal-timelines-label-farRight", selected: farRight)
      end

      def update_labels(left:, right:, farRight:)
        get_select(:left).find("option", text: left).select_option
        get_select(:right).find("option", text: right).select_option
        get_select(:farRight).find("option", text: farRight).select_option

        page.within ".spot-modal" do
          click_on "Apply"
        end
      end
    end
  end
end
