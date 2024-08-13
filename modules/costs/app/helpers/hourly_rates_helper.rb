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
                                .max_by(&:valid_from)

      return rate if rate
    end

    nil
  end
end
