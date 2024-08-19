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
  module LetWorkPackages
    # Declare work packages and relations from a visual chart representation.
    #
    # It uses +create_table+ internally and is useful to have direct access
    # to the created work packages.
    #
    # To see supported columns, see +TableHelpers::Column+.
    #
    # For instance:
    #
    #   let_work_packages(<<~TABLE)
    #     hierarchy   | work |
    #     parent      |   1h |
    #       child     | 2.5h |
    #     another one |      |
    #   TABLE
    #
    # is equivalent to:
    #
    #   let!(:_table) do
    #     create_table(table_representation)
    #   end
    #   let(:table_work_packages) do
    #     _table.work_packages
    #   end
    #   let(:parent) do
    #     _table.work_package(:parent)
    #   end
    #   let(:child) do
    #     _table.work_package(:child)
    #   end
    #   let(:another_one) do
    #     _table.work_package(:another_one)
    #   end
    def let_work_packages(table_representation)
      let!(:_table) { create_table(table_representation) }

      table_data = TableData.for(table_representation)
      let(:table_work_packages) { _table.work_packages }
      table_data.work_package_identifiers.each do |identifier|
        let(identifier) { _table.work_package(identifier) }
      end
    end

    # Declare work packages and relations from a visual chart representation.
    #
    # It uses +create_table+ internally and is useful to have direct access
    # to the created work packages.
    #
    # To see supported columns, see +TableHelpers::Column+.
    #
    # For instance:
    #
    #   shared_let_work_packages(<<~TABLE)
    #     hierarchy   | work |
    #     parent      |   1h |
    #       child     | 2.5h |
    #     another one |      |
    #   TABLE
    #
    # is equivalent to:
    #
    #   shared_let(:_table) do
    #     create_table(table_representation)
    #   end
    #   shared_let(:table_work_packages) do
    #     _table.work_packages
    #   end
    #   shared_let(:parent) do
    #     _table.work_package(:parent)
    #   end
    #   shared_let(:child) do
    #     _table.work_package(:child)
    #   end
    #   shared_let(:another_one) do
    #     _table.work_package(:another_one)
    #   end
    def shared_let_work_packages(table_representation)
      shared_let(:_table) { create_table(table_representation) }

      table_data = TableData.for(table_representation)
      shared_let(:table_work_packages) { _table.work_packages }
      table_data.work_package_identifiers.each do |identifier|
        shared_let(identifier) { _table.work_package(identifier) }
      end
    end
  end
end
