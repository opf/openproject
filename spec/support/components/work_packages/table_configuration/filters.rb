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

require_relative "../filters"

module Components
  module WorkPackages
    module TableConfiguration
      class Filters < ::Components::WorkPackages::Filters
        attr_reader :modal

        def initialize
          @modal = ::Components::WorkPackages::TableConfigurationModal.new
        end

        def open
          modal.open_and_switch_to "Filters"
          expect_open
        end

        delegate :save, to: :modal

        def expect_filter_count(count)
          within(modal.selector) do
            expect(page).to have_css(".advanced-filters--filter", count:)
          end
        end

        def expect_open
          modal.expect_open
          expect(page).to have_css(".op-tab-row--link_selected", text: "FILTERS")
        end

        delegate :expect_closed, to: :modal
      end
    end
  end
end
