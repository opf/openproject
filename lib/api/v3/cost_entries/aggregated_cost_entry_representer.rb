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

module API
  module V3
    module CostEntries
      # N.B. This class is currently quite specifically crafted for the aggregation of cost entries
      # of a single work package by their type. This might be improved in the future™
      class AggregatedCostEntryRepresenter < ::API::Decorators::Single
        def initialize(cost_type, units)
          @cost_type = cost_type
          @spent_units = units

          super(nil, current_user: nil)
        end

        linked_property :cost_type,
                        getter: -> { @cost_type },
                        embed_as: ::API::V3::CostTypes::CostTypeRepresenter

        property :spent_units,
                 exec_context: :decorator,
                 getter: ->(*) { @spent_units }

        def _type
          'AggregatedCostEntry'
        end

        def model_required?
          false
        end
      end
    end
  end
end
