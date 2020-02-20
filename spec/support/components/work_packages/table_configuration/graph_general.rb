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

module Components
  module WorkPackages
    module TableConfiguration
      class GraphGeneral
        include Capybara::DSL
        include RSpec::Matchers

        def set_type(name)
          within_modal do
            select name, from: "Chart type"
          end
        end

        def set_axis(name)
          within_modal do
            select name, from: "Axis criteria"
          end
        end

        def expect_type(name)
          within_modal do
            expect(page)
              .to have_select "Chart type", selected: name
          end
        end

        def expect_axis(name)
          within_modal do
            expect(page)
              .to have_select "Axis criteria", selected: name
          end
        end

        def apply
          within_modal do
            click_button('Apply')
          end
        end

        private

        def within_modal
          page.within('.wp-table--configuration-modal') do
            yield
          end
        end
      end
    end
  end
end
