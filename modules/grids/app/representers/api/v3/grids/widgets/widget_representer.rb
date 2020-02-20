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

module API
  module V3
    module Grids
      module Widgets
        class WidgetRepresenter < ::API::Decorators::Single
          property :id
          property :identifier
          property :start_row
          property :end_row
          property :start_column
          property :end_column

          property :options,
                   getter: ->(represented:, decorator:, **) {
                     ::Grids::Configuration
                       .widget_strategy(represented.grid.class, represented.identifier)
                       .options_representer
                       .constantize
                       .new(represented.options.with_indifferent_access.merge(grid: represented.grid),
                            current_user: decorator.current_user)
                   }

          def _type
            'GridWidget'
          end
        end
      end
    end
  end
end
