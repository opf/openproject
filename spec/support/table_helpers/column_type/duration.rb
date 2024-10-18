# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
  module ColumnType
    # Column type used for values that represent a duration like work and
    # remaining work.
    #
    # Parse hours or plain floats, for instance "2", "2h", or "3.5".
    # Format to hours, for instance "2h" or "3.5h".
    class Duration < Generic
      def text_align
        :rjust
      end

      def format(value)
        if value.nil?
          ""
        elsif value == value.truncate
          "%sh" % value.to_i
        else
          "%sh" % value
        end
      end

      def parse(raw_value)
        raw_value.blank? ? nil : raw_value.to_f
      end
    end
  end
end
