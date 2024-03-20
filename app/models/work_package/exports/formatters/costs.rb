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
module WorkPackage::Exports
  module Formatters
    class Costs < ::Exports::Formatters::Default
      def self.apply?(name, export_format)
        %i[material_costs labor_costs overall_costs].include?(name.to_sym) && export_format == :csv
      end

      def format_options
        { number_format: number_format_string }
      end

      def number_format_string
        # [$CUR] makes sure we have an actually working currency format with arbitrary currencies
        curr = "[$CUR]".gsub "CUR", ERB::Util.h(Setting.plugin_costs['costs_currency'])
        format = ERB::Util.h Setting.plugin_costs['costs_currency_format']
        number = '#,##0.00'

        format.gsub("%n", number).gsub("%u", curr)
      end
    end
  end
end
