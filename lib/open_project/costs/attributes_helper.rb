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

module OpenProject::Costs
  class AttributesHelper

    def initialize(work_package)
      @work_package = work_package
    end

    def overall_costs
      @overall_costs ||= compute_overall_costs
    end

    def summarized_cost_entries
      @summarized_cost_entries ||= compute_summarized_cost_entries
    end

    private

    def compute_overall_costs
      if material_costs || labor_costs
        sum_costs  = 0
        sum_costs += material_costs if material_costs
        sum_costs += labor_costs    if labor_costs
      else
        sum_costs = nil
      end
      sum_costs
    end

    def compute_summarized_cost_entries
      return {} if cost_entries.blank? || !user_allowed_to?(:view_cost_entries, :view_own_cost_entries)

      last_cost_type = ""

      cost_entries.sort_by(&:id).each_with_object({}) do |entry, hash|
        if entry.cost_type == last_cost_type
          hash[last_cost_type][:units] += entry.units
        else
          last_cost_type = entry.cost_type

          hash[last_cost_type] = {}
          hash[last_cost_type][:units] = entry.units
          hash[last_cost_type][:unit] = entry.cost_type.unit
          hash[last_cost_type][:unit_plural] = entry.cost_type.unit_plural
        end
      end
    end

    def time_entries
      @work_package.time_entries.visible(User.current, @work_package.project)
    end

    def material_costs
      cost_entries_with_rate = cost_entries.select{|c| c.costs_visible_by?(User.current)}
      cost_entries_with_rate.blank? ? nil : cost_entries_with_rate.collect(&:real_costs).sum
    end

    def labor_costs
      time_entries_with_rate = time_entries.select{|c| c.costs_visible_by?(User.current)}
      time_entries_with_rate.blank? ? nil : time_entries_with_rate.collect(&:real_costs).sum
    end

    def cost_entries
      @cost_entries ||= @work_package.cost_entries.visible(User.current, @work_package.project)
    end

    def user_allowed_to?(*privileges)
      privileges.inject(false) do |result, privilege|
        result || User.current.allowed_to?(privilege, @work_package.project)
      end
    end
  end
end
