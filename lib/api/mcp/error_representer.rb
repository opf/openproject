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

module API
  class Mcp
    class ErrorRepresenter
      INVALID_REQUEST = -32600
      INTERNAL_ERROR = -32603

      def initialize(error)
        @error = error
      end

      def to_json(*)
        {
          jsonrpc: "2.0",
          error: {
            code: map_code(@error.code),
            message: @error.message,
            data: @error.details
          }
        }.to_json(*)
      end

      private

      def map_code(code)
        return INTERNAL_ERROR if code >= 500

        INVALID_REQUEST
      end
    end
  end
end
