#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module OpPrimer
  class FlexLayoutComponent < Primer::Component
    def initialize(**)
      super

      @system_arguments = deny_tag_argument(**) || {}
      @system_arguments[:display] = :flex
    end

    renders_many :rows, lambda { |**system_arguments, &block|
      child_component(system_arguments, &block)
    }
    renders_many :columns, lambda { |**system_arguments, &block|
      child_component(system_arguments, &block)
    }
    # boxes are used when direction is set to row or column based on responsive breakpoints
    renders_many :boxes, lambda { |**system_arguments, &block|
      child_component(system_arguments, &block)
    }

    private

    def render?
      if rows.empty? && columns.empty? && boxes.empty?
        # no slot provided
        raise ArgumentError, "You have to provide either rows, columns or boxes as a slot"
      elsif [rows, columns, boxes].count { |arr| !arr.empty? } == 1
        # only rows or columns or boxes are used
        true
      else
        # rows, columns and boxes are used together, which is not allowed
        raise ArgumentError, "You can't mix row, column and box slots"
      end
    end

    def child_component(system_arguments, &)
      if system_arguments[:flex_layout] == true
        OpPrimer::FlexLayoutComponent.new(**system_arguments.except(:flex_layout), &)
      else
        Primer::Box.new(**system_arguments || {})
      end
    end
  end
end
