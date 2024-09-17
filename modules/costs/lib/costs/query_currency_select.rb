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

module Costs
  class QueryCurrencySelect < Queries::WorkPackages::Selects::WorkPackageSelect
    include ActionView::Helpers::NumberHelper
    alias :super_value :value

    def initialize(name, options = {})
      super
    end

    def value(work_package)
      number_to_currency(work_package.send(name))
    end

    def real_value(work_package)
      super_value work_package
    end

    class_attribute :currenty_selects

    self.currenty_selects = {
      budget: {},
      material_costs: {
        summable: ->(query, grouped) {
          scope = WorkPackage::MaterialCosts
                  .new(user: User.current)
                  .add_to_work_package_collection(WorkPackage.where(id: query.results.work_packages))
                  .except(:order, :select)

          Queries::WorkPackages::Selects::WorkPackageSelect
            .scoped_column_sum(scope,
                               "COALESCE(ROUND(SUM(cost_entries_sum), 2)::FLOAT, 0.0) material_costs",
                               grouped && query.group_by_statement)
        }
      },
      labor_costs: {
        summable: ->(query, grouped) {
          scope = WorkPackage::LaborCosts
                  .new(user: User.current)
                  .add_to_work_package_collection(WorkPackage.where(id: query.results.work_packages))
                  .except(:order, :select)

          Queries::WorkPackages::Selects::WorkPackageSelect
            .scoped_column_sum(scope,
                               "COALESCE(ROUND(SUM(time_entries_sum), 2)::FLOAT, 0.0) labor_costs",
                               grouped && query.group_by_statement)
        }
      },
      overall_costs: {
        summable: true,
        summable_select: "labor_costs + material_costs AS overall_costs",
        summable_work_packages_select: false
      }
    }

    def self.instances(context = nil)
      return [] if context && !context.costs_enabled?

      currenty_selects.map do |name, options|
        new(name, options)
      end
    end
  end
end
