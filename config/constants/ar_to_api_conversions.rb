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

module Constants
  class ARToAPIConversions
    # Conversions that are bidirectional:
    # * from the API to AR
    # * from AR to the API
    WELL_KNOWN_CONVERSIONS = {
      assigned_to: "assignee",
      version: "version",
      done_ratio: "percentageDone",
      derived_done_ratio: "derivedPercentageDone",
      estimated_hours: "estimatedTime",
      remaining_hours: "remainingTime",
      spent_hours: "spentTime",
      subproject: "subprojectId",
      relation_type: "type",
      mail: "email",
      column_names: "columns",
      sort_criteria: "sortBy",
      message: "post",
      firstname: "firstName",
      lastname: "lastName",
      member: "membership"
    }.freeze

    # Conversions that are unidirectional (from the API to AR)
    # This can be used to still support renamed filters/sort_by, like for created/updatedOn.
    WELL_KNOWN_API_TO_AR_CONVERSIONS = {
      created_on: "created_at",
      updated_on: "updated_at"
    }.freeze

    class << self
      def add(map)
        conversions.push(map)
      end

      def all
        conversions.inject(:merge)
      end

      def api_to_ar_conversions
        @api_to_ar_conversions ||= Constants::ARToAPIConversions.all.inject({}) do |result, (k, v)|
          result[v.underscore] = k.to_s
          result
        end.merge(WELL_KNOWN_API_TO_AR_CONVERSIONS.stringify_keys)
      end

      private

      def conversions
        @conversions ||= [WELL_KNOWN_CONVERSIONS]
      end
    end
  end
end
