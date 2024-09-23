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

module TableHelpers
  module ExampleMethods
    # Create work packages and relations from a visual chart representation.
    #
    # For instance:
    #
    #   create_table(<<~TABLE)
    #     hierarchy   | work |
    #     parent      |   1h |
    #       child     | 2.5h |
    #     another one |      |
    #   TABLE
    #
    # is equivalent to:
    #
    #   create(:work_package, subject: 'parent', estimated_hours: 1)
    #   create(:work_package, subject: 'child', parent: parent, estimated_hours: 2.5)
    #   create(:work_package, subject: 'another one')
    def create_table(table_representation)
      table_data = TableData.for(table_representation)
      table_data.create_work_packages
    end

    # Expect the given work packages to match a visual table representation.
    #
    # It uses +match_table+ internally and reloads the work packages from
    # database before comparing.
    #
    # For instance:
    #
    #   it 'is scheduled' do
    #     expect_work_packages(work_packages, <<~TABLE)
    #       subject | work | derived work |
    #       parent  |   1h |           3h |
    #       child   |   2h |           2h |
    #     TABLE
    #   end
    #
    # is equivalent to:
    #
    #   it 'is scheduled' do
    #     work_packages.each(&:reload)
    #     expect(work_packages).to match_table(<<~TABLE)
    #       subject | work | derived work |
    #       parent  |   1h |           3h |
    #       child   |   2h |           2h |
    #     TABLE
    #   end
    def expect_work_packages(work_packages, table_representation)
      work_packages.each(&:reload)
      expect(work_packages).to match_table(table_representation)
    end
  end
end
