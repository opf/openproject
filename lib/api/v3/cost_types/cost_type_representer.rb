#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module CostTypes
      class CostTypeRepresenter < Roar::Decorator
        include Roar::JSON::HAL
        include Roar::Hypermedia
        include OpenProject::StaticRouting::UrlHelpers

        self.as_strategy = API::Utilities::CamelCasingStrategy.new

        def initialize(model, unit_summary, options = {}, *expand)
          @summary = unit_summary
          @work_package = options[:work_package]
          @current_user = options[:current_user]

          super(model)
        end

        property :_type, exec_context: :decorator

        property :id, render_nil: true
        property :name, render_nil: true
        property :units,
                 getter: -> (*) {
                   cost_entries = @work_package.cost_entries
                                               .visible(@current_user, @work_package.project)
                                               .where(cost_type_id: represented.id)

                   cost_entries.sum(&:units)
                 },
                 exec_context: :decorator,
                 render_nil: true
        property :unit,
                 exec_context: :decorator,
                 getter: -> (*) { @summary[:unit] },
                 render_nil: true
        property :unit_plural,
                 exec_context: :decorator,
                 getter: -> (*) { @summary[:unit_plural] },
                 render_nil: true

        def _type
          'CostType'
        end
      end
    end
  end
end
