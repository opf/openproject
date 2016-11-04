#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

module OpenProject::Costs::Patches::QueryPatch
  class CurrencyQueryColumn < QueryColumn
    include ActionView::Helpers::NumberHelper
    alias :super_value :value

    def initialize(name, options = {})
      super

      @sum_function = options[:summable]
      self.summable = @sum_function.respond_to?(:call)
    end

    def value(work_package)
      number_to_currency(work_package.send(name))
    end

    def real_value(work_package)
      super_value work_package
    end

    def xls_formatter
      :cost
    end

    def xls_value(work_package)
      super_value work_package
    end

    def sum_of(work_packages)
      @sum_function.call(work_packages)
    end
  end

  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      add_available_column(QueryColumn.new(:cost_object))

      add_available_column(CurrencyQueryColumn.new(
                             :material_costs,
                             summable: -> (work_packages) {
                               WorkPackage::MaterialCosts
                                 .new(user: User.current)
                                 .costs_of(work_packages: work_packages)
                             }))

      add_available_column(CurrencyQueryColumn.new(
                             :labor_costs,
                             summable: -> (work_packages) {
                               WorkPackage::LaborCosts
                                 .new(user: User.current)
                                 .costs_of(work_packages: work_packages)
                             }))

      add_available_column(CurrencyQueryColumn.new(
                             :overall_costs,
                             summable: -> (work_packages) {
                               labor_costs = WorkPackage::LaborCosts
                                 .new(user: User.current)
                                 .costs_of(work_packages: work_packages)

                               material_costs = WorkPackage::MaterialCosts
                                 .new(user: User.current)
                                 .costs_of(work_packages: work_packages)

                               labor_costs + material_costs
                             }))
    end
  end

  module ClassMethods
  end

  module InstanceMethods
  end
end
