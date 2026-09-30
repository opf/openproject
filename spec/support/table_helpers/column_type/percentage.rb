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
  module ColumnType
    # Column type used for values that represent a percentage like % complete.
    #
    # Parse percentage or plain integers, for instance "10", "20%", or "100%".
    # Format to percentage, for instance "2%" or "35%".
    class Percentage < Generic
      def text_align
        :rjust
      end

      def format(value)
        if value.nil?
          ""
        else
          "%s%%" % value.to_i
        end
      end

      def parse(raw_value)
        raw_value.blank? ? nil : raw_value.to_i
      end
    end
  end
end
