#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

module API
  module V3
    module Grids
      class GridRepresenter < ::API::Decorators::Single
        link :page do
          {
            href: my_page_path
          }
        end

        property :row_count,
                 exec_context: :decorator

        property :column_count,
                 exec_context: :decorator

        property :widgets,
                 exec_context: :decorator

        def _type
          'Grid'
        end

        def row_count
          4
        end

        def column_count
          5
        end

        def widgets
          [
            {
              "_type": "Widget",
              "identifier": 'work_packages_assigned',
              "startRow": '2',
              "endRow": '4',
              "startColumn": '2',
              "endColumn": '4'
            },
            {
              "_type": "Widget",
              "identifier": 'work_packages_created',
              "startRow": '1',
              "endRow": '2',
              "startColumn": '1',
              "endColumn": '6'
            },
            {
              "_type": "Widget",
              "identifier": 'work_packages_watched',
              "startRow": '2',
              "endRow": '4',
              "startColumn": '4',
              "endColumn": '6'
            }
          ]
        end
      end
    end
  end
end
