# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackage::SchedulingRules
  extend ActiveSupport::Concern

  def schedule_automatically?
    !schedule_manually?
  end

  # Calculates the minimum date that will not violate the precedes relations
  # (max(finish date, start date) + relation lag) of this work package or its
  # ancestors
  #
  # Lag is the number of non working days between 2 work packages of a
  # follows/precedes relation.
  #
  # For instance:
  #          AP -------------- precedes ----- A
  # (due_date: 2017/07/25)     (lag: 0)       |
  #                                         parent
  #                                           |
  #          BP -------------- precedes ----- B
  # (due_date: 2017/07/22)     (lag: 2)       |
  #                                         parent
  #                                           |
  #          CP -------------- precedes ----- C
  # (due_date: 2017/07/25)     (lag: 2)
  #
  # Then successor_soonest_start for each relation is:
  #   A is 2017/07/26 (AP due date: 25, no lag => 26)
  #   B is 2017/07/27 (BP due date: 22, 23 and 24 are non-working days, 25 and 26 is the 2 days lag => 27)
  #   C is 2017/07/28 (CP due date: 25, 26 and 27 is the 2 days lag => 28)
  #
  # The soonest start for this work package is the maximum of these values: 2017/07/28.
  #
  # @param working_days_from [WorkPackage, nil] the work package for which to
  #   find the next working day after the soonest start given by the scheduling
  #   relations. If nil, the work package itself is used. Useful for a work
  #   package calculating the soonest start given by its parent as it may have a
  #   different `ignore_working_days` value than its parent.
  def soonest_start(working_days_from: nil)
    @scheduling_relations_soonest_start ||=
      Relation
        .used_for_scheduling_of(self)
        .includes(:to) # eager load `to` to avoid n+1 in #successor_soonest_start
        .filter_map(&:successor_soonest_start)
        .max

    # The final result should not be cached as it depends on
    # ignore_non_working_days value, which can change between consecutive calls
    # to #soonest_start
    days = WorkPackages::Shared::Days.for(working_days_from || self)
    days.soonest_working_day(@scheduling_relations_soonest_start)
  end
end
