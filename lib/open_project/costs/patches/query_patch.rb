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
      add_available_column(QueryColumn.new(:cost_object_subject))

      add_available_column(CurrencyQueryColumn.new(
                             :material_costs,
                             summable: -> (work_packages) {
                               CostEntry.costs_of(work_packages: work_packages)
                             }))

      add_available_column(CurrencyQueryColumn.new(
                             :labor_costs,
                             summable: -> (work_packages) {
                               TimeEntry.costs_of(work_packages: work_packages)
                             }))

      add_available_column(CurrencyQueryColumn.new(
                             :overall_costs,
                             summable: -> (work_packages) {
                               labor_costs = TimeEntry.costs_of(work_packages: work_packages)
                               material_costs = CostEntry.costs_of(work_packages: work_packages)
                               labor_costs + material_costs
                             }))

      Queries::WorkPackages::Filter.add_filter_type_by_field('cost_object_id', 'list_optional')

      alias_method_chain :available_work_package_filters, :costs
    end
  end

  module ClassMethods
  end

  module InstanceMethods
    # Wrapper around the +available_filters+ to add a new Cost Object filter
    def available_work_package_filters_with_costs
      @available_filters = available_work_package_filters_without_costs

      if project && project.module_enabled?(:costs_module)
        openproject_costs_filters = {
          'cost_object_id' => {
            type: :list_optional,
            order: 14,
            values: CostObject.where(project_id: project)
                    .order('subject ASC')
                    .pluck(:subject, :id)
          },
        }
      else
        openproject_costs_filters = {}
      end
      @available_filters.merge(openproject_costs_filters)
    end
  end
end
