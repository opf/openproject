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
  class AttributesHelper
    def initialize(work_package, user = User.current)
      @work_package = work_package
      @user = user
    end

    def overall_costs
      @overall_costs ||= compute_overall_costs
    end

    def summarized_cost_entries
      @summarized_cost_entries ||= cost_entries.group(:cost_type).calculate(:sum, :units)
    end

    def time_entries
      if @work_package.time_entries.loaded?
        @work_package.time_entries.select do |time_entry|
          !time_entry.ongoing && time_entry.visible_by?(@user)
        end
      else
        @work_package.time_entries.not_ongoing.visible(@user, @work_package.project)
      end
    end

    def cost_entries
      @cost_entries ||= if @work_package.cost_entries.loaded?
                          @work_package.cost_entries.select do |cost_entry|
                            cost_entry.costs_visible_by?(@user)
                          end
                        else
                          @work_package.cost_entries.visible(@user, @work_package.project)
                        end
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

    def material_costs
      cost_entries_with_rate = cost_entries.select { |c| c.costs_visible_by?(@user) }
      cost_entries_with_rate.blank? ? nil : cost_entries_with_rate.sum(&:real_costs)
    end

    def labor_costs
      time_entries_with_rate = time_entries.select { |c| c.costs_visible_by?(@user) }
      time_entries_with_rate.blank? ? nil : time_entries_with_rate.sum(&:real_costs)
    end
  end
end
