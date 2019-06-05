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

module HourlyRatesHelper
  include CostlogHelper

  # Returns the rate that is the closest at the specified date and that is
  # defined in the specified projects or it's ancestors. The ancestor chain
  # is traversed from the specified project upwards.
  #
  # Expects all_rates to be all the rates that the user possibly has
  # grouped by project typically by having called HourlyRates.history_for_user
  #
  # This is faster than calling current_rate for each project
  def at_date_in_project_with_ancestors(at_date, all_rates, project)
    self_and_ancestors = all_rates.keys
                                  .select { |ancestor| ancestor.lft <= project.lft && ancestor.rgt >= project.rgt }
                                  .sort_by(&:lft)
                                  .reverse

    self_and_ancestors.each do |ancestor|
      rate = all_rates[ancestor].select { |rate| rate.valid_from <= at_date }
                                .sort_by(&:valid_from)
                                .last

      return rate if rate
    end

    return nil
  end
end
