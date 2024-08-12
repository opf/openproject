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
module WorkPackage::Exports
  module Formatters
    class SpentUnits < ::Exports::Formatters::Default
      def self.apply?(name, _export_format)
        %i[costs_by_type spent_units].include?(name.to_sym)
      end

      def format(work_package, **)
        cost_helper = ::Costs::AttributesHelper.new(work_package, User.current)
        values = cost_helper.summarized_cost_entries.map do |kvp|
          cost_type = kvp[0]
          volume = kvp[1]
          BigDecimal("1.0")
          type_unit = volume.to_d == BigDecimal("1.0") ? cost_type.unit : cost_type.unit_plural
          "#{volume} #{type_unit}"
        end
        return nil if values.empty?

        values.join(", ")
      end
    end
  end
end
