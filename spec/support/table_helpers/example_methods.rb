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

    # Change the given work packages according to the given table representation.
    # Work packages are changed without being saved.
    #
    # The first column gives the identifier of the work package to update, so it
    # cannot be used to update the subject or the hierarchy.
    #
    # For instance:
    #
    #   before do
    #     update_work_packages([main], <<~TABLE)
    #       subject | MTWTFSS | scheduling mode |
    #       main    | XX      | manual          |
    #     TABLE
    #   end
    #
    # is equivalent to:
    #
    #   before do
    #     main.start_date = monday
    #     main.due_date = tuesday
    #     main.schedule_manually = true
    #   end
    def change_work_packages(work_packages, table_representation)
      TableData.for(table_representation).work_packages_data.pluck(:attributes).each do |attributes|
        work_package = work_packages.find { |wp| wp.subject == attributes[:subject] }
        unless work_package
          raise ArgumentError, "no work package with subject #{attributes[:subject]} given; " \
                               "available work packages are #{work_packages.pluck(:subject).to_sentence}"
        end

        attributes.without(:subject).each do |attribute, value|
          work_package.send(:"#{attribute}=", value)
        end
      end
    end

    # Expect the given work packages to match a visual table representation.
    #
    # It uses +match_table+ internally. It does not reload the work packages
    # before comparing. To reload, use `expect_work_packages_after_reload`
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
    #     expect(work_packages).to match_table(<<~TABLE)
    #       subject | work | derived work |
    #       parent  |   1h |           3h |
    #       child   |   2h |           2h |
    #     TABLE
    #   end
    def expect_work_packages(work_packages, table_representation)
      expect(work_packages).to match_table(table_representation)
    end

    # Expect the given work packages to match a visual table representation
    # after being reloaded.
    #
    # It uses +match_table+ internally and reloads the work packages from
    # database before comparing.
    #
    # For instance:
    #
    #   it 'is scheduled' do
    #     expect_work_packages_after_reload(work_packages, <<~TABLE)
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
    def expect_work_packages_after_reload(work_packages, table_representation)
      work_packages.each(&:reload)
      expect_work_packages(work_packages, table_representation)
    end
  end
end
