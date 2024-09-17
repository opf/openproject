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

module API
  module V3
    module CostEntries
      # N.B. This class is currently quite specifically crafted for the aggregation of cost entries
      # of a single work package by their type. This might be improved in the future™
      class AggregatedCostEntryRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource

        def initialize(cost_type, units)
          @cost_type = cost_type
          @spent_units = units

          super(nil, current_user: nil)
        end

        resource :costType,
                 link: ->(*) {
                   {
                     href: api_v3_paths.cost_type(@cost_type.id),
                     title: @cost_type.name
                   }
                 },
                 getter: ->(*) {
                   ::API::V3::CostTypes::CostTypeRepresenter.new(@cost_type, current_user:)
                 },
                 setter: ->(*) {}

        property :budget_id,
                 exec_context: :decorator,
                 getter: ->(*) {
                   @cost_type.id
                 }

        property :spent_units,
                 exec_context: :decorator,
                 getter: ->(*) { @spent_units }

        link :staticPath do
          {
            href: budget_path(@cost_type.id)
          }
        end

        def _type
          "AggregatedCostEntry"
        end

        def model_required?
          false
        end
      end
    end
  end
end
