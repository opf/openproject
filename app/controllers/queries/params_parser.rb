# -- copyright
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
# ++
module Queries
  class ParamsParser
    class << self
      def parse(params)
        query_params = {}

        query_params[:filters] = parse_filters_from_params(params) if params[:filters].present?
        query_params[:orders] = parse_orders_from_params(params) if params[:sortBy].present?
        query_params[:selects] = parse_columns_from_params(params) if params[:columns].present?

        query_params
      end

      private

      def parse_filters_from_params(params)
        if params[:filters].present? && params[:filters].start_with?("[")
          ::Queries::ParamsParser::APIV3FiltersParser.parse(params[:filters])
        else
          FiltersParser.new(params[:filters]).parse
        end
      end

      def parse_orders_from_params(params)
        JSON.parse(params[:sortBy])
            .to_h
            .map { |k, v| { attribute: k, direction: v } }
      rescue JSON::ParserError
        [{ attribute: "invalid", direction: "asc" }]
      end

      def parse_columns_from_params(params)
        params[:columns].split
      end
    end
  end
end
